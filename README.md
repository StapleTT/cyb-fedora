# cyb-fedora

Fedora 44 setup scripts for a cybersecurity lab environment.

## Modules

| # | Module | What it installs |
|---|--------|-----------------|
| 1 | Quality of Life | fish, neovim, starship, AdwaitaMono Nerd Font, Ctrl+Alt+T shortcut, rustup, eza |
| 2 | Alfa Wi-Fi driver | RTL8812AU via DKMS (aircrack-ng fork, patched for kernel 6.x) |
| 3 | Cybersecurity tools | nmap, wireshark, hydra, sqlmap, impacket, pwntools, feroxbuster, SecLists, and more |

## Usage

```bash
git clone https://github.com/StapleTT/cyb-fedora
cd cyb-fedora
bash install.sh
```

Select a module number at the prompt, or `4` to run all three in order.

## Notes

- Run as a normal user, not root. Scripts will call `sudo` where needed.
- Module 2 requires the kernel headers for your running kernel (`kernel-devel-$(uname -r)`).
- Module 3 installs Rust tools via cargo -- run module 1 first if you want feroxbuster and rustscan.
- `hashcat/hashcat.sh` is a standalone script for NVIDIA driver + CUDA + hashcat setup. It is not included in the installer yet and must be run manually (spoiler alert: it's broken. Will probably break your system).
