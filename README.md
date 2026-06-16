# caelestia (Fedora edition)

This is the main repo of the caelestia dots and contains the user configs for
apps. This repo also includes an install script to install the entire dots.

> [!NOTE]
> This is a community **Fedora fork** of
> [`caelestia-dots/caelestia`](https://github.com/caelestia-dots/caelestia).
> Upstream targets Arch Linux only (AUR metapackage + `install.fish`). This
> fork adds [`install-fedora.sh`](install-fedora.sh) — a `dnf`/COPR port of
> the installer — plus a [Fedora dependency map](docs/FEDORA.md), while keeping
> the upstream Arch path untouched. See [Fedora installation](#fedora-installation)
> below. Public and free under the same GPL-3.0 license as upstream.

## Installation

Simply clone this repo and run the install script (you need
[`fish`](https://github.com/fish-shell/fish-shell) installed).

> [!WARNING]
> The install script symlinks all configs into place, so you CANNOT
> move/remove the repo folder once you run the install script. If
> you do, most apps will not behave properly and some (e.g. Hyprland)
> will fail to start completely. I recommend cloning the repo to
> `~/.local/share/caelestia`.

The install script has some options for installing configs for some apps.

```
$ ./install.fish -h
usage: ./install.sh [-h] [--noconfirm] [--spotify] [--vscode] [--discord] [--aur-helper]

options:
  -h, --help                  show this help message and exit
  --noconfirm                 do not confirm package installation
  --spotify                   install Spotify (Spicetify)
  --vscode=[codium|code]      install VSCodium (or VSCode)
  --discord                   install Discord (OpenAsar + Equicord)
  --zen                       install Zen browser
  --aur-helper=[yay|paru]     the AUR helper to use
```

For example:

```sh
git clone https://github.com/caelestia-dots/caelestia.git ~/.local/share/caelestia
~/.local/share/caelestia/install.fish
```

### Fedora installation

Caelestia has no native Fedora package. Use the bundled `dnf`/COPR port:

```sh
git clone https://github.com/YaxOFF/caelestia-fedora.git ~/.local/share/caelestia
cd ~/.local/share/caelestia
./install-fedora.sh
```

What it does:

1.  Enables RPM Fusion and the required COPRs
    (`sdegler/hyprland` for Hyprland/hyprpicker, `errornointernet/quickshell`
    for Quickshell).
2.  Installs the dependency set via `dnf` (mapped from the upstream
    `caelestia-meta` PKGBUILD — see [docs/FEDORA.md](docs/FEDORA.md)).
3.  Builds `caelestia-cli` (pip, into `~/.local`) and installs
    `caelestia-shell` (Quickshell config) from source, since neither is
    packaged for Fedora.
4.  Pulls the few items Fedora does not package — JetBrains Mono Nerd Font and
    `app2unit` — into `~/.local`.
5.  Symlinks the same config set as the Arch installer (`hypr`, `foot`, `fish`,
    `fastfetch`, `uwsm`, `btop`, `starship.toml`).

```
$ ./install-fedora.sh -h
usage: ./install-fedora.sh [-h] [--noconfirm] [--no-copr] [--no-build] [--configs-only]

options:
  -h, --help        show this help message and exit
  --noconfirm       pass -y to dnf and never prompt before overwriting configs
  --no-copr         skip enabling COPR/RPM Fusion repos (assume already set up)
  --no-build        skip building caelestia-cli / caelestia-shell from source
  --configs-only    only symlink the configs (no package install, no build)
```

> [!WARNING]
> Like the Arch installer, this symlinks configs into place — do not move or
> delete the repo folder afterwards, or Hyprland will fail to start. Clone to a
> stable location such as `~/.local/share/caelestia`.

> [!NOTE]
> Tested on Fedora 43 with Hyprland from the `sdegler/hyprland` COPR. Package
> availability in COPRs can change; the script installs packages one-by-one and
> reports anything it could not pull so you can grab it manually.

### Manual installation

Dependencies:

-   hyprland
-   xdg-desktop-portal-hyprland
-   xdg-desktop-portal-gtk
-   hyprpicker
-   wl-clipboard
-   cliphist
-   inotify-tools
-   app2unit
-   wireplumber
-   trash-cli
-   foot
-   fish
-   fastfetch
-   starship
-   btop
-   jq
-   eza
-   adw-gtk-theme
-   papirus-icon-theme
-   qtengine-git
-   ttf-jetbrains-mono-nerd

Install all dependencies and follow the installation guides of the
[shell](https://github.com/caelestia-dots/shell) and [cli](https://github.com/caelestia-dots/cli)
to install them.

> [!TIP]
> If on Arch or an Arch-based distro, there is a meta package available [in this repository](PKGBUILD)
> that pulls in all dependencies. It can be installed through the install script, makepkg/pacman, yay,
> paru, or your preferred AUR helper.

Then copy or symlink the `hypr`, `foot`, `fish`, `fastfetch`, `uwsm` and `btop` folders to the
`$XDG_CONFIG_HOME` (usually `~/.config`) directory. e.g. `hypr -> ~/.config/hypr`.
Copy `starship.toml` to `$XDG_CONFIG_HOME/starship.toml`.

#### Installing Spicetify configs:

Follow the Spicetify [installation instructions](https://spicetify.app/docs/advanced-usage/installation),
copy or symlink the `spicetify` folder to `$XDG_CONFIG_HOME/spicetify` and run

```sh
spicetify config current_theme caelestia color_scheme caelestia custom_apps marketplace
spicetify apply
```

#### Installing VSCode/VSCodium configs:

Install VSCode or VSCodium, then copy or symlink `vscode/settings.json` and
`vscode/keybindings.json` into the `$XDG_CONFIG_HOME/Code/User` (or `$XDG_CONFIG_HOME/VSCodium/User`
if using VSCodium) folder. Then copy or symlink `vscode/flags.conf` to `$XDG_CONFIG_HOME/code-flags.conf`
(or `$XDG_CONFIG_HOME/codium-flags.conf` if using VSCodium).

Finally, install the extension VSIX from `vscode/caelestia-vscode-integration`.

```sh
# Use `codium` if using VSCodium
code --install-extension vscode/caelestia-vscode-integration/caelestia-vscode-integration-*.vsix
```

#### Installing Zen Browser configs:

Install Zen Browser, then copy or symlink `zen/userChrome.css` to the `chrome` folder in your
profile of choice in `~/.zen`. e.g. `zen/userChrome.css -> ~/.zen/<profile>/chrome/userChrome.css`.

Now install the native app by copying `zen/native_app/manifest.json` to
`~/.mozilla/native-messaging-hosts/caelestiafox.json` and replacing the `{{ $lib }}` string in it
with the absolute path of `~/.local/lib/caelestia` (this must be the absolute path, e.g.
`/home/user/.local/lib/caelestia`). Then copy or symlink `zen/native_app/app.fish` to
`~/.local/lib/caelestia/caelestiafox`.

Finally, install the CaelestiaFox extension from [here](https://addons.mozilla.org/en-US/firefox/addon/caelestiafox).

## Updating

Simply run `yay` to update the AUR packages, then `cd` into the repo directory and run `git pull` to update the configs.

## Usage

> [!NOTE]
> These dots do not contain a login manager (for now), so you must install a
> login manager yourself unless you want to log in from a TTY. I recommend
> [`greetd`](https://sr.ht/~kennylevinsen/greetd) with
> [`tuigreet`](https://github.com/apognu/tuigreet), however you can use
> any login manager you want.

There aren't really any usage instructions... these are a set of dotfiles.

Here's a list of useful keybinds though:

-   `Super` - open launcher
-   `Super` + `#` - switch to workspace `#`
-   `Super` `Alt` + `#` - move window to workspace `#`
-   `Super` + `T` - open terminal (foot)
-   `Super` + `W` - open browser (zen)
-   `Super` + `C` - open IDE (vscodium)
-   `Super` + `S` - toggle special workspace or close current special workspace
-   `Ctrl` `Alt` + `Delete` - open session menu
-   `Ctrl` `Super` + `Space` - toggle media play state
-   `Ctrl` `Super` `Alt` + `R` - restart the shell
