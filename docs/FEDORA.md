# Fedora dependency map

Caelestia is built and packaged for Arch Linux. The upstream dependency list
lives in the [`caelestia-meta` PKGBUILD](../PKGBUILD). This document maps every
dependency to its Fedora equivalent and records where the names differ, where a
COPR is needed, and where the component has to be built from source.

The automated installer ([`install-fedora.sh`](../install-fedora.sh)) applies
this mapping. This file exists so the mapping can be reviewed and maintained
independently of the script.

> Validated on **Fedora 43** (Hyprland from `sdegler/hyprland`, Quickshell from
> `errornointernet/quickshell`).

## Repositories required

| Repo | Purpose |
|------|---------|
| RPM Fusion (free + nonfree) | codecs / ffmpeg / misc |
| COPR `sdegler/hyprland` | Hyprland, hyprpicker (closer to upstream than Fedora's own pkg) |
| COPR `errornointernet/quickshell` | Quickshell — runtime for `caelestia-shell`, not in Fedora repos |

## Core dependencies

| Arch package (PKGBUILD) | Fedora package | Notes |
|-------------------------|----------------|-------|
| `caelestia-cli` | *(build from source)* | `pip install --user` from [`cli`](https://github.com/caelestia-dots/cli); needs Python ≥ 3.13 |
| `caelestia-shell` | *(build from source)* | Quickshell config from [`shell`](https://github.com/caelestia-dots/shell), symlinked into `~/.config/quickshell/caelestia` |
| `hyprland` | `hyprland` | COPR `sdegler/hyprland` (also in Fedora repos on F41+) |
| `xdg-desktop-portal-hyprland` | `xdg-desktop-portal-hyprland` | |
| `xdg-desktop-portal-gtk` | `xdg-desktop-portal-gtk` | |
| `hyprpicker` | `hyprpicker` | COPR `sdegler/hyprland` |
| `wl-clipboard` | `wl-clipboard` | |
| `cliphist` | `cliphist` | |
| `inotify-tools` | `inotify-tools` | |
| `app2unit` | *(install from source)* | Not packaged; script fetches the upstream script into `~/.local/bin` |
| `wireplumber` | `wireplumber` | usually already installed |
| `trash-cli` | `trash-cli` | |
| `foot` | `foot` | |
| `fish` | `fish` | |
| `eza` | `eza` | |
| `fastfetch` | `fastfetch` | |
| `starship` | `starship` | |
| `btop` | `btop` | |
| `jq` | `jq` | |
| `adw-gtk-theme` | `adw-gtk3-theme` | **name differs** |
| `papirus-icon-theme` | `papirus-icon-theme` | |
| `qtengine` / qt6ct | `qt6ct` | Qt6 platform theming |
| `ttf-jetbrains-mono-nerd` | *(install from source)* | Fedora's `jetbrains-mono-fonts` is **not** Nerd-patched; script pulls the patched TTFs from ryanoasis/nerd-fonts |

## caelestia-cli build / runtime extras

These are pulled in by the script for the CLI's screenshot, recording and
colour-scheme features (the CLI shells out to them at runtime):

| Tool | Fedora package |
|------|----------------|
| Python toolchain | `python3 python3-pip python3-devel` |
| Screenshot / annotate | `grim slurp swappy` |
| `notify-send` | `libnotify` |
| Sass (scheme gen) | `dart-sass` |

The CLI's own Python deps (`materialyoucolor`, `pillow`) are resolved
automatically by `pip` during the source build.

## Known gaps / caveats

- **COPR drift** — COPR contents change over time. The installer installs
  packages one at a time and prints anything it could not install so you can
  source it manually.
- **Quickshell** — if `errornointernet/quickshell` is unavailable for your
  Fedora version, build Quickshell from source per its
  [docs](https://github.com/quickshell-mirror/quickshell).
- **Login manager** — like upstream, these dots do not ship one. Install
  greetd/SDDM/etc. yourself.
- **Optional apps** — Spotify/Spicetify, VSCode, Discord and Zen (the
  `--spotify`/`--vscode`/`--discord`/`--zen` flags of the Arch `install.fish`)
  are **not** ported here. Install them via `dnf`/Flatpak and symlink the
  configs from this repo manually if wanted.
