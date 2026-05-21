#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
printf '\e[1;36m'
cat << 'BANNER'
  ██████╗██╗   ██╗██████╗       ███████╗███████╗████████╗██╗   ██╗██████╗
 ██╔════╝╚██╗ ██╔╝██╔══██╗      ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
 ██║      ╚████╔╝ ██████╔╝█████╗███████╗█████╗     ██║   ██║   ██║██████╔╝
 ██║       ╚██╔╝  ██╔══██╗╚════╝╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
 ╚██████╗   ██║   ██████╔╝      ███████║███████╗   ██║   ╚██████╔╝██║
  ╚═════╝   ╚═╝   ╚═════╝       ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝
BANNER
printf '\e[0m'
echo

printf '\e[1;37m  Fedora 44 lab setup — select a module to install:\e[0m\n'
echo
printf '  \e[1;32m[1]\e[0m  Quality of Life      — fish, nvim, starship, fonts, shortcuts\n'
printf '  \e[1;32m[2]\e[0m  Alfa Wi-Fi driver    — RTL8812AU (aircrack-ng fork, kernel 6.x patches)\n'
printf '  \e[1;32m[3]\e[0m  Cybersecurity tools  — Kali-equivalent toolset for Fedora\n'
printf '  \e[1;32m[4]\e[0m  All of the above\n'
printf '  \e[1;31m[q]\e[0m  Quit\n'
echo
printf '  Choice: '
read -r choice
echo

run() {
    local script="$1"
    if [[ ! -f "$script" ]]; then
        printf '\e[1;31m[install]\e[0m Script not found: %s\n' "$script" >&2
        exit 1
    fi
    bash "$script"
}

case "$choice" in
    1) run "$SCRIPT_DIR/qol/qol.sh" ;;
    2) run "$SCRIPT_DIR/alfa/alfa.sh" ;;
    3) run "$SCRIPT_DIR/cyb/cyb.sh" ;;
    4)
        run "$SCRIPT_DIR/qol/qol.sh"
        run "$SCRIPT_DIR/alfa/alfa.sh"
        run "$SCRIPT_DIR/cyb/cyb.sh"
        ;;
    q|Q) echo "Bye." ; exit 0 ;;
    *) printf '\e[1;31m[install]\e[0m Invalid choice: %s\n' "$choice" >&2 ; exit 1 ;;
esac
