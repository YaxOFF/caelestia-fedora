#!/usr/bin/env bash
#
# Caelestia dotfiles installer for Fedora Linux.
#
# Caelestia ships natively only for Arch (AUR metapackage + install.fish).
# This script is a Fedora/dnf port: it enables the needed COPR/RPM Fusion
# repos, installs the dependency set via dnf, builds the caelestia-cli and
# caelestia-shell components from source (no Fedora package exists for them),
# and symlinks the app configs into place exactly like the upstream
# install.fish does.
#
# Dependency mapping is derived from the upstream PKGBUILD metapackage and
# was validated on Fedora 43 (Hyprland via the sdegler/hyprland COPR,
# Quickshell via the errornointernet/quickshell COPR).
#
# Usage:
#   ./install-fedora.sh [-h] [--noconfirm] [--no-copr] [--no-build] [--configs-only]
#
# Options:
#   -h, --help        show this help message and exit
#   --noconfirm       pass -y to dnf and never prompt before overwriting configs
#   --no-copr         skip enabling COPR/RPM Fusion repos (assume already set up)
#   --no-build        skip building caelestia-cli / caelestia-shell from source
#   --configs-only    only symlink the configs (no package install, no build)
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------
NOCONFIRM=0
DO_COPR=1
DO_BUILD=1
CONFIGS_ONLY=0

usage() {
    sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-0}"
}

for arg in "$@"; do
    case "$arg" in
        -h|--help)     usage 0 ;;
        --noconfirm)   NOCONFIRM=1 ;;
        --no-copr)     DO_COPR=0 ;;
        --no-build)    DO_BUILD=0 ;;
        --configs-only) CONFIGS_ONLY=1; DO_COPR=0; DO_BUILD=0 ;;
        *) echo "Unknown option: $arg" >&2; usage 1 ;;
    esac
done

DNF_YES=""
[ "$NOCONFIRM" -eq 1 ] && DNF_YES="-y"

CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
INSTALL_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# ---------------------------------------------------------------------------
# Pretty output (mirrors install.fish log/input helpers)
# ---------------------------------------------------------------------------
c_cyan=$'\e[36m'; c_blue=$'\e[34m'; c_magenta=$'\e[35m'
c_yellow=$'\e[33m'; c_red=$'\e[31m'; c_reset=$'\e[0m'

log()   { printf '%s:: %s%s\n' "$c_cyan"   "$1" "$c_reset"; }
input() { printf '%s:: %s%s'   "$c_blue"   "$1" "$c_reset"; }
warn()  { printf '%s:: %s%s\n' "$c_yellow" "$1" "$c_reset"; }
err()   { printf '%s:: %s%s\n' "$c_red"    "$1" "$c_reset" >&2; }

# confirm-overwrite <path>  -> returns 0 if caller should (re)install, 1 to skip
confirm_overwrite() {
    local path="$1"
    if [ -e "$path" ] || [ -L "$path" ]; then
        if [ "$NOCONFIRM" -eq 1 ]; then
            log "$path already exists. Overwriting..."
            rm -rf "$path"
            return 0
        fi
        input "$path already exists. Overwrite? [Y/n] "
        local reply; read -r reply
        case "$reply" in
            n|N) log 'Skipping...'; return 1 ;;
            *)   log 'Removing...'; rm -rf "$path"; return 0 ;;
        esac
    fi
    return 0
}

# symlink-config <src-rel> <dest>  -- link a repo folder/file into place
link_config() {
    local src="$INSTALL_DIR/$1" dest="$2"
    if confirm_overwrite "$dest"; then
        log "Installing $(basename "$dest") config..."
        mkdir -p "$(dirname "$dest")"
        ln -s "$(readlink -f "$src")" "$dest"
    fi
}

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
printf '%s' "$c_magenta"
cat <<'EOF'
╭─────────────────────────────────────────────────╮
│      ______           __          __  _         │
│     / ____/___ ____  / /__  _____/ /_(_)___ _   │
│    / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/   │
│   / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /    │
│   \____/\__,_/\___/_/\___/____/\__/_/\__,_/     │
│                  Fedora edition                 │
╰─────────────────────────────────────────────────╯
EOF
printf '%s' "$c_reset"
log 'Welcome to the Caelestia dotfiles installer (Fedora port)!'
log 'Make sure you have a backup of your ~/.config before continuing.'

if [ "$(id -u)" -eq 0 ]; then
    err 'Do not run this script as root. It uses sudo only where needed.'
    exit 1
fi

# ===========================================================================
# 1. Repositories
# ===========================================================================
if [ "$DO_COPR" -eq 1 ]; then
    log 'Enabling required repositories...'

    sudo dnf install $DNF_YES dnf-plugins-core

    # RPM Fusion (free + nonfree) for ffmpeg/codecs and misc packages.
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        log 'Enabling RPM Fusion...'
        sudo dnf install $DNF_YES \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi

    # Hyprland + ecosystem. As of Fedora 41+ Hyprland is also in the official
    # repos, but the sdegler COPR tracks upstream more closely and carries
    # hyprpicker etc.
    log 'Enabling Hyprland COPR (sdegler/hyprland)...'
    sudo dnf copr enable $DNF_YES sdegler/hyprland || \
        warn 'Could not enable sdegler/hyprland COPR; will fall back to Fedora repos.'

    # Quickshell — required runtime for caelestia-shell. Not in Fedora repos.
    log 'Enabling Quickshell COPR (errornointernet/quickshell)...'
    sudo dnf copr enable $DNF_YES errornointernet/quickshell || \
        warn 'Could not enable Quickshell COPR; you may need to build Quickshell from source.'
fi

# ===========================================================================
# 2. Dependencies (dnf)
# ===========================================================================
if [ "$CONFIGS_ONLY" -eq 0 ]; then
    log 'Installing dependencies via dnf...'

    # Mapped from the upstream caelestia-meta PKGBUILD. Fedora package names
    # differ from Arch in several cases (noted inline).
    PKGS=(
        # --- Compositor / portals ---
        hyprland
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
        hyprpicker            # from sdegler COPR

        # --- Quickshell (caelestia-shell runtime) ---
        quickshell            # from errornointernet COPR

        # --- Wayland clipboard / utils ---
        wl-clipboard
        cliphist
        inotify-tools
        wireplumber
        trash-cli             # Arch: trash-cli

        # --- Terminal / shell tooling ---
        foot
        fish
        eza
        fastfetch
        starship
        btop
        jq

        # --- caelestia-cli build + runtime deps ---
        python3 python3-pip python3-devel
        grim slurp swappy           # screenshot/record pipeline
        libnotify                   # provides notify-send
        dart-sass                   # scheme generation (sass); Arch: dart-sass

        # --- Theming / fonts / Qt ---
        adw-gtk3-theme              # Arch: adw-gtk-theme
        papirus-icon-theme
        qt6ct                       # Arch: qtengine / qt6ct
        jetbrains-mono-fonts        # Nerd-patched variant installed separately below
    )

    # Install one-by-one so a single missing package does not abort everything;
    # report what could not be installed at the end.
    MISSING=()
    for pkg in "${PKGS[@]}"; do
        if ! sudo dnf install $DNF_YES "$pkg"; then
            warn "Could not install '$pkg' from configured repos."
            MISSING+=("$pkg")
        fi
    done

    if [ "${#MISSING[@]}" -gt 0 ]; then
        warn "The following packages were not installed automatically: ${MISSING[*]}"
        warn 'Install them manually (COPR / source) before launching the shell.'
    fi

    # JetBrains Mono Nerd Font — not packaged by Fedora; fetch the patched TTFs.
    NERD_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    if [ ! -d "$NERD_DIR" ]; then
        log 'Installing JetBrains Mono Nerd Font...'
        tmp_zip="$(mktemp --suffix=.zip)"
        if curl -fSL -o "$tmp_zip" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip; then
            mkdir -p "$NERD_DIR"
            ( cd "$NERD_DIR" && bsdtar -xf "$tmp_zip" 2>/dev/null || unzip -oq "$tmp_zip" )
            fc-cache -f "$NERD_DIR" >/dev/null
        else
            warn 'Could not download JetBrains Mono Nerd Font; install it manually.'
        fi
        rm -f "$tmp_zip"
    fi

    # app2unit — not in Fedora repos. Pull the upstream script into ~/.local/bin.
    if ! command -v app2unit &>/dev/null; then
        log 'Installing app2unit (not packaged for Fedora)...'
        mkdir -p "$HOME/.local/bin"
        if curl -fSL -o "$HOME/.local/bin/app2unit" \
            https://raw.githubusercontent.com/Vladimir-csp/app2unit/main/app2unit; then
            chmod +x "$HOME/.local/bin/app2unit"
        else
            warn 'Could not fetch app2unit; install it manually from https://github.com/Vladimir-csp/app2unit'
        fi
    fi
fi

# ===========================================================================
# 3. Build caelestia-cli and caelestia-shell from source
# ===========================================================================
if [ "$DO_BUILD" -eq 1 ]; then
    SRC="$HOME/.local/share/caelestia/src"
    mkdir -p "$SRC"

    # --- caelestia-cli (Python, pip install into ~/.local) ---
    log 'Building caelestia-cli from source...'
    if [ -d "$SRC/cli/.git" ]; then
        git -C "$SRC/cli" pull --ff-only || true
    else
        git clone https://github.com/caelestia-dots/cli.git "$SRC/cli"
    fi
    python3 -m pip install --user --upgrade "$SRC/cli" || \
        warn 'caelestia-cli pip install failed; check Python >= 3.13 is available.'

    # --- caelestia-shell (Quickshell config) ---
    log 'Installing caelestia-shell...'
    if [ -d "$SRC/shell/.git" ]; then
        git -C "$SRC/shell" pull --ff-only || true
    else
        git clone https://github.com/caelestia-dots/shell.git "$SRC/shell"
    fi
    if confirm_overwrite "$CONFIG/quickshell/caelestia"; then
        log 'Linking caelestia-shell into ~/.config/quickshell...'
        mkdir -p "$CONFIG/quickshell"
        ln -s "$(readlink -f "$SRC/shell")" "$CONFIG/quickshell/caelestia"
    fi

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) : ;;
        *) warn 'Add ~/.local/bin to your PATH so the `caelestia` command is found.' ;;
    esac
fi

# ===========================================================================
# 4. Symlink app configs (identical set to upstream install.fish)
# ===========================================================================
log 'Installing app configs...'
link_config hypr          "$CONFIG/hypr"
link_config starship.toml "$CONFIG/starship.toml"
link_config foot          "$CONFIG/foot"
link_config fish          "$CONFIG/fish"
link_config fastfetch     "$CONFIG/fastfetch"
link_config uwsm          "$CONFIG/uwsm"
link_config btop          "$CONFIG/btop"

# Make the workspace-action script executable, like install.fish does.
[ -f "$CONFIG/hypr/scripts/wsaction.fish" ] && chmod u+x "$CONFIG/hypr/scripts/wsaction.fish"

# ===========================================================================
# 5. First-run scheme + launch
# ===========================================================================
if command -v caelestia &>/dev/null; then
    if [ ! -f "$STATE/caelestia/scheme.json" ]; then
        log 'Generating initial colour scheme...'
        caelestia scheme set -n shadotheme || true
    fi
    command -v hyprctl &>/dev/null && hyprctl reload || true
fi

log 'Done! Log into a Hyprland session and run `caelestia shell -d` to start the shell.'
warn 'These dots do not ship a login manager — install greetd/SDDM/etc. yourself.'
