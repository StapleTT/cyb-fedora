#!/usr/bin/env bash
set -euo pipefail

# ── helpers ───────────────────────────────────────────────────────────────────
info()  { printf '\e[1;34m[cyb]\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m[cyb]\e[0m %s\n' "$*"; }
warn()  { printf '\e[1;33m[cyb]\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m[cyb]\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as a normal user, not root."

TOOLS_DIR="/opt/sectools"
sudo mkdir -p "$TOOLS_DIR"
sudo chown "$USER":"$USER" "$TOOLS_DIR"

clone_or_update() {
    local url="$1" dest="$2"
    if [[ -d "$dest/.git" ]]; then
        info "Updating $(basename "$dest")..."
        git -C "$dest" pull --ff-only 2>/dev/null || warn "Could not update $(basename "$dest"), skipping."
    else
        info "Cloning $(basename "$dest")..."
        git clone --depth=1 "$url" "$dest"
    fi
}

# ── RPM Fusion (free + nonfree) ───────────────────────────────────────────────
info "Enabling RPM Fusion free and nonfree..."
sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm" \
    2>/dev/null || true

# ── DNF packages ──────────────────────────────────────────────────────────────

# -- Reconnaissance & scanning ------------------------------------------------
info "Installing reconnaissance and scanning tools..."
sudo dnf install -y \
    nmap nmap-ncat masscan \
    dnsenum whois bind-utils traceroute \
    gobuster ffuf whatweb \
    proxychains-ng

# -- Web & application testing ------------------------------------------------
info "Installing web testing tools..."
sudo dnf install -y \
    wireshark wireshark-cli tcpdump socat netcat

# -- SMB / Active Directory ---------------------------------------------------
info "Installing SMB/AD tools..."
sudo dnf install -y \
    samba-client \
    ldap-utils 2>/dev/null || \
sudo dnf install -y samba-client

# -- Password attacks ----------------------------------------------------------
info "Installing password attack tools..."
sudo dnf install -y \
    hydra medusa ncrack \
    john pdfcrack steghide

# -- Wireless -----------------------------------------------------------------
info "Installing wireless tools..."
sudo dnf install -y aircrack-ng

# -- Forensics & steganography ------------------------------------------------
info "Installing forensics tools..."
sudo dnf install -y \
    binwalk foremost sleuthkit \
    perl-Image-ExifTool \
    hexedit bless ghex

# -- Reverse engineering & debugging ------------------------------------------
info "Installing reverse engineering tools..."
sudo dnf install -y \
    radare2 gdb strace ltrace

# -- Tunneling & anonymity ----------------------------------------------------
info "Installing tunneling and anonymity tools..."
sudo dnf install -y openvpn tor

# -- Build deps and Python toolchain ------------------------------------------
info "Installing build dependencies..."
sudo dnf install -y \
    python3-pip python3-devel pipx \
    openssl-devel libffi-devel gcc make \
    perl perl-Net-SSLeay perl-LWP-Protocol-https \
    git curl wget ruby ruby-devel

# ── pipx tools (Python CLI) ───────────────────────────────────────────────────
info "Installing Python security tools via pipx..."

pipx_install() {
    pipx install "$1" 2>/dev/null || pipx upgrade "$1" 2>/dev/null || warn "pipx: $1 skipped"
}

pipx_install sqlmap
pipx_install impacket
pipx_install pwntools
pipx_install wfuzz
pipx_install scapy
pipx_install certipy-ad
pipx_install netexec
pipx_install "git+https://github.com/laramies/theHarvester"

# ── Cargo tools (Rust) ────────────────────────────────────────────────────────
if command -v cargo &>/dev/null; then
    info "Installing Rust security tools via cargo..."
    cargo install feroxbuster 2>/dev/null || warn "feroxbuster install failed"
    cargo install rustscan    2>/dev/null || warn "rustscan install failed"
else
    warn "cargo not found — skipping feroxbuster and rustscan."
    warn "Run qol/qol.sh first to install rustup, then re-run this script."
fi

# ── Git-cloned tools → /opt/sectools ─────────────────────────────────────────
info "Cloning tools into $TOOLS_DIR..."

# nikto (Perl web scanner, not in Fedora repos)
clone_or_update "https://github.com/sullo/nikto"          "$TOOLS_DIR/nikto"
sudo ln -sf "$TOOLS_DIR/nikto/program/nikto.pl" /usr/local/bin/nikto 2>/dev/null || true

# enum4linux-ng (SMB/AD enumeration)
clone_or_update "https://github.com/cddmp/enum4linux-ng"  "$TOOLS_DIR/enum4linux-ng"
sudo ln -sf "$TOOLS_DIR/enum4linux-ng/enum4linux-ng.py" /usr/local/bin/enum4linux-ng 2>/dev/null || true

# Responder (LLMNR/NBT-NS poisoner)
clone_or_update "https://github.com/lgandx/Responder"      "$TOOLS_DIR/Responder"

# LinPEAS / WinPEAS (privilege escalation scripts)
clone_or_update "https://github.com/peass-ng/PEASS-ng"     "$TOOLS_DIR/PEASS-ng"

# PayloadsAllTheThings (payload and bypass reference)
clone_or_update "https://github.com/swisskyrepo/PayloadsAllTheThings" "$TOOLS_DIR/PayloadsAllTheThings"

# exploitdb / searchsploit
clone_or_update "https://gitlab.com/exploit-database/exploitdb" "$TOOLS_DIR/exploitdb"
sudo ln -sf "$TOOLS_DIR/exploitdb/searchsploit" /usr/local/bin/searchsploit 2>/dev/null || true
[[ -d ~/.searchsploit_rc ]] && rm -rf ~/.searchsploit_rc
cat > ~/.searchsploit_rc << EOF
EXPLOIT_DB_PATH=$TOOLS_DIR/exploitdb
EOF

# ── Wordlists ─────────────────────────────────────────────────────────────────
info "Cloning SecLists (this is ~1.8 GB, please wait)..."
clone_or_update "https://github.com/danielmiessler/SecLists" "$TOOLS_DIR/SecLists"
sudo ln -sfn "$TOOLS_DIR/SecLists" /usr/share/seclists 2>/dev/null || true

# rockyou.txt (extract if not already present)
ROCKYOU="/usr/share/wordlists/rockyou.txt"
if [[ ! -f "$ROCKYOU" ]]; then
    info "Installing rockyou.txt..."
    sudo mkdir -p /usr/share/wordlists
    curl -fL "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt" \
        | sudo tee "$ROCKYOU" > /dev/null
fi

# ── Symlinks for convenience ──────────────────────────────────────────────────
sudo ln -sfn "$TOOLS_DIR" /opt/sectools 2>/dev/null || true

ok "──────────────────────────────────────────────"
ok "All cybersecurity tools installed."
ok ""
ok "Tool locations:"
ok "  dnf tools     → in PATH as normal"
ok "  pipx tools    → ~/.local/bin  (sqlmap, nxc, certipy, ...)"
ok "  cargo tools   → ~/.cargo/bin  (feroxbuster, rustscan)"
ok "  cloned tools  → $TOOLS_DIR"
ok "  SecLists      → /usr/share/seclists"
ok "  rockyou.txt   → $ROCKYOU"
ok "──────────────────────────────────────────────"
