#!/usr/bin/env bash
set -euo pipefail

# ── helpers ──────────────────────────────────────────────────────────────────
info()  { printf '\e[1;34m[qol]\e[0m %s\n' "$*"; }
ok()    { printf '\e[1;32m[qol]\e[0m %s\n' "$*"; }
die()   { printf '\e[1;31m[qol]\e[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as a normal user, not root."

# ── packages ─────────────────────────────────────────────────────────────────
info "Installing fish and neovim..."
sudo dnf install -y fish neovim unzip

# ── embedded dotfiles (base64-encoded tar.gz archives) ───────────────────────
FISH_B64="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"

NVIM_B64="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"

# starship.toml is embedded verbatim below
read -r -d '' STARSHIP_TOML << 'TOMLEOF' || true
"$schema" = 'https://starship.rs/config-schema.json'

[aws]
symbol = " "

[azure]
symbol = " "

[battery]
full_symbol = "󰁹 "
charging_symbol = "󰂄 "
discharging_symbol = "󰂃 "
unknown_symbol = "󰂑 "
empty_symbol = "󰂎 "

[buf]
symbol = " "

[bun]
symbol = " "

[c]
symbol = " "

[cpp]
symbol = " "

[cmake]
symbol = " "

[cobol]
symbol = " "

[conda]
symbol = " "

[container]
symbol = " "

[crystal]
symbol = " "

[dart]
symbol = " "

[deno]
symbol = " "

[direnv]
symbol = " "

[directory]
read_only = " 󰌾"

[docker_context]
symbol = " "

[dotnet]
symbol = " "

[elixir]
symbol = " "

[elm]
symbol = " "

[erlang]
symbol = " "

[fennel]
symbol = " "

[fortran]
symbol = " "

[fossil_branch]
symbol = " "

[gcloud]
symbol = "󱇶 "

[gleam]
symbol = " "

[git_branch]
symbol = " "

[git_commit]
tag_symbol = '  '

[golang]
symbol = " "

[gradle]
symbol = " "

[guix_shell]
symbol = " "

[haskell]
symbol = " "

[haxe]
symbol = " "

[helm]
symbol = " "

[hg_branch]
symbol = " "

[hostname]
ssh_symbol = " "

[java]
symbol = " "

[julia]
symbol = " "

[kotlin]
symbol = " "

[kubernetes]
symbol = "󱃾 "

[lua]
symbol = " "

[maven]
symbol = " "

[memory_usage]
symbol = "󰍛 "

[meson]
symbol = "󰔷 "

[mojo]
symbol = "󰈸 "

[nats]
symbol = " "

[netns]
symbol = "󰛳 "

[nim]
symbol = " "

[nix_shell]
symbol = " "

[nodejs]
symbol = " "

[ocaml]
symbol = " "

[odin]
symbol = "󰟢 "

[opa]
symbol = " "

[openstack]
symbol = " "

[os.symbols]
AIX = " "
AlmaLinux = " "
Alpaquita = " "
Alpine = " "
ALTLinux = " "
Amazon = " "
Android = " "
AOSC = " "
Arch = " "
Artix = " "
Bluefin = " "
CachyOS = " "
CentOS = " "
Debian = " "
DragonFly = " "
Elementary = " "
Emscripten = " "
EndeavourOS = " "
Fedora = " "
FreeBSD = " "
Garuda = " "
Gentoo = " "
HardenedBSD = "󰞌 "
Illumos = " "
InstantOS = " "
Ios = "󰀷 "
Kali = " "
Linux = " "
Mabox = " "
Macos = " "
Manjaro = " "
Mariner = " "
MidnightBSD = " "
Mint = " "
NetBSD = " "
NixOS = " "
Nobara = " "
OpenBSD = " "
OpenCloudOS = " "
openEuler = " "
openSUSE = " "
OracleLinux = "󰺡 "
PikaOS = " "
Pop = " "
Raspbian = " "
Redhat = "󱄛 "
RedHatEnterprise = "󱄛 "
Redox = "󰀘 "
RockyLinux = " "
Solus = " "
SUSE = " "
Ubuntu = " "
Ultramarine = " "
Unknown = " "
Uos = " "
Void = " "
Windows = "󰍲 "
Zorin = " "

[package]
symbol = "󰏗 "

[perl]
symbol = " "

[php]
symbol = " "

[pijul_channel]
symbol = " "

[pixi]
symbol = "󰏗 "

[pulumi]
symbol = " "

[purescript]
symbol = " "

[python]
symbol = " "

[raku]
symbol = "󱖊 "

[red]
symbol = "󱍼 "

[rlang]
symbol = "󰟔 "

[ruby]
symbol = " "

[rust]
symbol = "󱘗 "

[scala]
symbol = " "

[shlvl]
symbol = "󰹍 "

[singularity]
symbol = " "

[solidity]
symbol = " "

[spack]
symbol = " "

[status]
symbol = " "

[sudo]
symbol = " "

[swift]
symbol = " "

[terraform]
symbol = " "

[vlang]
symbol = " "

[typst]
symbol = " "

[vagrant]
symbol = " "

[xmake]
symbol = " "

[zig]
symbol = " "
TOMLEOF

# ── deploy dotfiles ───────────────────────────────────────────────────────────
info "Deploying fish config..."
rm -rf ~/.config/fish
echo "$FISH_B64" | base64 -d | tar xzf - -C ~/.config/
ok "fish config installed."

info "Deploying nvim config..."
rm -rf ~/.config/nvim
echo "$NVIM_B64" | base64 -d | tar xzf - -C ~/.config/
ok "nvim config installed."

info "Deploying starship.toml..."
printf '%s\n' "$STARSHIP_TOML" > ~/.config/starship.toml
ok "starship.toml installed."

# ── AdwaitaMono Nerd Font ─────────────────────────────────────────────────────
info "Installing AdwaitaMono Nerd Font..."
FONT_DIR="/usr/local/share/fonts/AdwaitaMono"
FONT_TMP=$(mktemp -d)
trap 'rm -rf "$FONT_TMP"' EXIT

curl -fL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AdwaitaMono.zip" \
     -o "$FONT_TMP/AdwaitaMono.zip"
unzip -q "$FONT_TMP/AdwaitaMono.zip" -d "$FONT_TMP/AdwaitaMono"
sudo mkdir -p "$FONT_DIR"
sudo cp "$FONT_TMP"/AdwaitaMono/*.ttf "$FONT_DIR/"
sudo fc-cache -fv "$FONT_DIR" > /dev/null
ok "AdwaitaMono Nerd Font installed."

# ── Ptyxis terminal font ──────────────────────────────────────────────────────
info "Setting Ptyxis terminal font to AdwaitaMono Nerd Font Mono..."
gsettings set org.gnome.Ptyxis use-system-font false
gsettings set org.gnome.Ptyxis font-name 'Adwaita Mono Regular 11'
ok "Terminal font updated."

# ── Ptyxis session restore ────────────────────────────────────────────────────
info "Disabling Ptyxis session restore..."
gsettings set org.gnome.Ptyxis restore-session false
ok "Ptyxis session restore disabled."

# ── GNOME shortcut: Ctrl+Alt+T → ptyxis ──────────────────────────────────────
info "Adding Ctrl+Alt+T → terminal shortcut..."
BINDING_PATH='/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/'
EXISTING=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
if [[ "$EXISTING" == "@as []" ]]; then
    gsettings set org.gnome.settings-daemon.plugins.media-keys \
        custom-keybindings "['$BINDING_PATH']"
elif [[ "$EXISTING" != *"$BINDING_PATH"* ]]; then
    NEW="${EXISTING%]}, '$BINDING_PATH']"
    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$NEW"
fi
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" \
    name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" \
    command 'ptyxis'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:"$BINDING_PATH" \
    binding '<Control><Alt>t'
ok "Ctrl+Alt+T shortcut added."

# ── rustup + cargo + eza ──────────────────────────────────────────────────────
info "Installing rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
info "Installing build dependencies..."
sudo dnf install -y gcc
info "Installing eza..."
cargo install eza
ok "Rust toolchain and eza installed."

# ── starship ──────────────────────────────────────────────────────────────────
info "Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh -s -- -y
ok "starship installed."

ok "All done! Restart your shell or run: exec fish"
