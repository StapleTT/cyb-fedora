#!/usr/bin/env bash
set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────
info()  { printf '\e[1;34m[alfa]\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m[alfa]\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m[alfa]\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as a normal user, not root."

# ── dependencies ─────────────────────────────────────────────────────────────
info "Installing build dependencies..."
sudo dnf install -y git dkms "kernel-devel-$(uname -r)" gcc make

# ── clone and install driver ─────────────────────────────────────────────────
DRIVER_TMP=$(mktemp -d)
trap 'rm -rf "$DRIVER_TMP"' EXIT

info "Cloning aircrack-ng/rtl8812au..."
git clone --depth=1 https://github.com/aircrack-ng/rtl8812au.git "$DRIVER_TMP/rtl8812au"

info "Patching driver for kernel 6.x compatibility..."
# EXTRA_CFLAGS was removed in 6.x — include paths require ccflags-y
sed -i 's/EXTRA_CFLAGS/ccflags-y/g' "$DRIVER_TMP/rtl8812au/Makefile"
# from_timer() and del_timer_sync() were removed in 6.13
find "$DRIVER_TMP/rtl8812au" \( -name '*.c' -o -name '*.h' \) \
    -exec sed -i \
        's/from_timer(/timer_container_of(/g;
         s/del_timer_sync(/timer_delete_sync(/g' {} +
# cfg80211 callbacks gained int radio_idx in 6.17 (multi-radio support)
python3 - "$DRIVER_TMP/rtl8812au/os_dep/linux/ioctl_cfg80211.c" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    src = f.read()

src = src.replace(
    'cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, u32 changed)',
    'cfg80211_rtw_set_wiphy_params(struct wiphy *wiphy, int radio_idx, u32 changed)'
)
src = src.replace(
    '\tstruct wireless_dev *wdev,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 36)) || defined(COMPAT_KERNEL_RELEASE)\n\tenum nl80211_tx_power_setting type, int mbm)',
    '\tstruct wireless_dev *wdev,\n\tint radio_idx,\n#endif\n#if (LINUX_VERSION_CODE >= KERNEL_VERSION(2, 6, 36)) || defined(COMPAT_KERNEL_RELEASE)\n\tenum nl80211_tx_power_setting type, int mbm)'
)
src = src.replace(
    '#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 14, 0))\n\tunsigned int link_id,\n#endif',
    '#if (LINUX_VERSION_CODE >= KERNEL_VERSION(6, 14, 0))\n\tint radio_idx,\n\tunsigned int link_id,\n#endif'
)

with open(path, 'w') as f:
    f.write(src)
print("cfg80211 radio_idx patches applied.")
PYEOF

info "Removing any previous RTL8812AU DKMS entries..."
for ver in $(ls /var/lib/dkms/8812au/ 2>/dev/null); do
    sudo dkms remove "8812au/$ver" --all 2>/dev/null || true
done
sudo rm -rf /usr/src/8812au-*

info "Installing RTL8812AU driver via DKMS..."
cd "$DRIVER_TMP/rtl8812au"
sudo make dkms_install

ok "RTL8812AU driver installed. Plug in your Alfa adapter and it should be ready."
ok "A reboot may be required if this is the first install."
