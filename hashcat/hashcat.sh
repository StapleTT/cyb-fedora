#!/usr/bin/env bash
# WIP — not yet included in install.sh; CUDA toolkit install on Fedora still
# needs validation (cuda-toolkit metapackage requires Java via cuda-visual-tools).
set -euo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────
info()  { printf '\e[1;34m[hashcat]\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m[hashcat]\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m[hashcat]\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m[hashcat]\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as a normal user, not root."

MOK_FLAG="$HOME/.cache/hashcat-mok-enrolled"

# ── Detect GPU and pick driver branch ─────────────────────────────────────────
# Blackwell (GB2xx) and Ada Lovelace (AD1xx) require the open kernel module.
# The closed driver does not recognise these GPU IDs and returns Invalid argument.
GPU_DESC=$(lspci | grep -i nvidia | grep -iE 'vga|3d|display' | head -1)
[[ -z "$GPU_DESC" ]] && die "No NVIDIA GPU detected."
info "GPU detected: $GPU_DESC"

if echo "$GPU_DESC" | grep -qiE 'GB[0-9]|AD[0-9]'; then
    NVIDIA_PKG="akmod-nvidia-open"
else
    NVIDIA_PKG="akmod-nvidia"
fi
info "Driver package: $NVIDIA_PKG"

# ── Disable el9 repos before touching NVIDIA packages ────────────────────────
# el9-tagged packages from the CUDA repo are incompatible with Fedora and will
# shadow RPM Fusion if both repos are enabled during driver installation.
info "Checking for el9 repos that could interfere with driver install..."
while read -r repo_id; do
    warn "Disabling incompatible el9 repo: $repo_id"
    sudo dnf config-manager setopt "${repo_id}.enabled=0"
done < <(dnf repolist --enabled 2>/dev/null | awk 'NR>1{print $1}' | grep -iE 'el9|rhel9' || true)

# ── Secure Boot: MOK key enrollment ──────────────────────────────────────────
SB_STATE=$(mokutil --sb-state 2>/dev/null || echo "unknown")

if [[ "$SB_STATE" == *"enabled"* ]]; then
    MOK_KEY="/etc/pki/akmods/certs/public_key.der"

    if [[ ! -f "$MOK_FLAG" ]]; then
        info "Secure Boot is active — generating and enrolling akmods MOK key..."

        # Generate the per-kernel signing key pair
        sudo systemctl start "akmods-keygen@$(uname -r)" 2>/dev/null || true

        if [[ ! -f "$MOK_KEY" ]]; then
            die "MOK key not found at $MOK_KEY after keygen. Check: systemctl status akmods-keygen@$(uname -r)"
        fi

        # Queue the key for MOK enrolment
        sudo mokutil --import "$MOK_KEY"
        touch "$MOK_FLAG"

        echo
        warn "╔══════════════════════════════════════════════════════════════╗"
        warn "║  REBOOT REQUIRED — MOK KEY ENROLLMENT                       ║"
        warn "║                                                              ║"
        warn "║  1. Reboot now.                                              ║"
        warn "║  2. At the blue MOK Manager screen, select 'Enroll MOK'.    ║"
        warn "║  3. Select 'Continue' → 'Yes' → enter the password you set. ║"
        warn "║  4. Select 'Reboot'.                                         ║"
        warn "║  5. Re-run this script after booting back in.               ║"
        warn "╚══════════════════════════════════════════════════════════════╝"
        exit 0
    fi

    # Verify the key is actually enrolled before proceeding
    if ! sudo mokutil --test-key "$MOK_KEY" &>/dev/null; then
        die "MOK key not yet enrolled. Reboot and enroll it via MOK Manager, then re-run."
    fi
    ok "MOK key enrolled — continuing with driver install."
else
    info "Secure Boot is not active, skipping MOK enrollment."
fi

# ── Install NVIDIA driver (RPM Fusion only, CUDA repo disabled) ───────────────
info "Installing $NVIDIA_PKG from RPM Fusion..."
sudo dnf install -y \
    --exclude='kernel,kernel-core,kernel-modules,kernel-modules-core,kernel-modules-extra' \
    "$NVIDIA_PKG" xorg-x11-drv-nvidia-cuda

# ── Wait for kernel module to finish building ─────────────────────────────────
# Rebooting before the module is built causes a nouveau fallback.
info "Waiting for NVIDIA kernel module to build (up to 10 min)..."
for i in $(seq 1 60); do
    if modinfo -F version nvidia &>/dev/null; then
        ok "Module built: $(modinfo -F version nvidia)"
        break
    fi
    [[ $i -eq 60 ]] && die "Module build timed out after 10 min. Run: sudo akmods --force"
    printf '.'
    sleep 10
done
echo

# Regenerate initramfs so the new module is included on next boot
info "Regenerating initramfs..."
sudo dracut --force

# ── CUDA toolkit (NVIDIA repo, isolated install) ──────────────────────────────
info "Adding NVIDIA CUDA repository..."
if [[ ! -f /etc/yum.repos.d/cuda-rhel9.repo ]]; then
    sudo dnf config-manager addrepo \
        --from-repofile=https://developer.download.nvidia.com/compute/cuda/repos/rhel9/x86_64/cuda-rhel9.repo
fi

info "Installing CUDA toolkit (from CUDA repo only)..."
# 'cuda-toolkit' pulls in cuda-visual-tools → cuda-nsight/nvvp → jre, which is
# not available on Fedora. Install individual components instead: compiler,
# runtime headers, and GPU libraries — everything hashcat and CUDA dev need.
CUDA_SLOT=$(sudo dnf list available --disablerepo='*' --enablerepo='cuda-rhel9-x86_64' \
    'cuda-nvcc-*' 2>/dev/null \
    | awk '/^cuda-nvcc-/{print $1}' \
    | grep -oP '(?<=cuda-nvcc-)\d+-\d+' \
    | sort -t- -k1,1n -k2,2n | tail -1)
[[ -z "$CUDA_SLOT" ]] && die "Could not find any cuda-nvcc package in the CUDA repo."
info "Installing CUDA $CUDA_SLOT components..."
sudo dnf install -y --nogpgcheck \
    --disablerepo='*' --enablerepo='cuda-rhel9-x86_64' \
    "cuda-nvcc-${CUDA_SLOT}" \
    "cuda-cudart-devel-${CUDA_SLOT}" \
    "cuda-libraries-${CUDA_SLOT}"

# Keep the CUDA repo disabled after install so it can't interfere with future
# NVIDIA driver updates coming from RPM Fusion.
sudo dnf config-manager setopt "cuda-rhel9-x86_64.enabled=0"
ok "CUDA repo disabled (re-enable manually if you need to update the toolkit)."

# ── hashcat ───────────────────────────────────────────────────────────────────
info "Installing hashcat..."
sudo dnf install -y hashcat

# ── Pin current kernel as GRUB default ───────────────────────────────────────
# akmod-nvidia may pull in a newer kernel; ensure the running kernel boots next.
CURRENT_VMLINUZ="/boot/vmlinuz-$(uname -r)"
if [[ -f "$CURRENT_VMLINUZ" ]]; then
    info "Pinning $(uname -r) as GRUB default..."
    sudo grubby --set-default "$CURRENT_VMLINUZ"
    ok "GRUB default set to $(uname -r)."
else
    warn "Could not find $CURRENT_VMLINUZ — verify GRUB default manually with: grubby --default-kernel"
fi

ok "All done! Reboot to load the NVIDIA driver."
ok "After rebooting, verify with:"
ok "  lsmod | grep nvidia"
ok "  nvidia-smi"
ok "  hashcat -I"
