# Dotfiles

Configs and a bootstrap script for my Arch Linux laptop, plus a smaller set for
macOS. The laptop is a Lenovo Legion Pro 7 (16IRX8H: i9-13900HX, RTX 4080
Laptop GPU, 32 GB, 2560x1600 at 240 Hz) running Hyprland under uwsm, with a
Quickshell bar. Its GPU MUX is set to discrete only; [hypr/README.md](hypr/README.md#gpu)
explains what that means and how to switch to hybrid.

Each top-level directory is a GNU stow package that mirrors `$HOME`.
`setup.sh` installs packages, stows the configs, copies a few system files and
enables services.

## Packages

| Package | Configures | macOS |
|---|---|---|
| `aerospace` | AeroSpace, the tiling window manager, laid out like the Hyprland binds | only |
| `alacritty` | Alacritty, plus `xdg-terminal-exec` so apps opened from Thunar find it | |
| `autostart` | Hides nm-applet's autostart entry | |
| `bat` | bat, in the terminal's colours | yes |
| `btop` | btop, in the terminal's colours, with the GPU | yes |
| `desktop` | Default apps, Chromium's video decoding flags, hidden launcher entries | |
| `editors` | Code - OSS settings | |
| `fontconfig` | Noto fonts for Arabic, Japanese and Chinese | |
| `fuzzel` | The app launcher | |
| `gamemode` | GameMode | |
| `ghostty` | Ghostty, the terminal on macOS | only |
| `gitconfig` | git settings and aliases ([README](gitconfig/README.md)) | yes |
| `hypr` | Hyprland, hypridle, hyprlock, hyprpaper, hyprsunset ([README](hypr/README.md)) | |
| `mangohud` | The MangoHud overlay | |
| `mpv` | mpv | yes |
| `nvim` | Neovim | yes |
| `pacman` | makepkg settings for AUR builds | |
| `pipewire`, `wireplumber` | Audio drop-ins (see [Audio](#audio)) | |
| `quickshell` | The bar, panels, OSD and notifications ([README](quickshell/README.md)) | |
| `starship` | The prompt | yes |
| `thunar` | Thunar's terminal action and its F4 shortcut | |
| `uwsm` | The session environment | |
| `zsh` | zsh and its plugins ([README](zsh/README.md)) | yes |

`setup/` isn't stowed. It holds the package lists (`setup/packages/*.txt`, with
`aur/` marking AUR packages), the units to enable (`services.txt`), the system
files (`system/`), GTK settings (`dconf/`) and the Brewfile (`macos/`).

## Fresh install

1. Install Arch with NetworkManager, systemd-boot and git; archinstall is fine.
   Use LUKS2 disk encryption next time: the current install has none.
2. Clone the repo and let `setup.sh` bring the machine in line:

   ```bash
   git clone https://github.com/muhamadgameel/dotfiles.git ~/Projects/dotfiles
   cd ~/Projects/dotfiles
   ./setup.sh            # report what's missing; changes nothing
   ./setup.sh install    # fix it, asking per item
   ```

   `install` asks for sudo once, then works through its steps in order:
   pacman (multilib, mirrors), packages, stow, AUR (it builds yay first),
   system files, user settings, services.
3. Reboot, so zram, the new initramfs and the audio settings apply. In SDDM pick
   **Hyprland (uwsm-managed)**; the plain Hyprland entry is hidden, because
   without uwsm the bar, idle lock, wallpaper and night light never start.
4. Restore your SSH and GPG keys. `./setup.sh` reports whether they're there.

## Day to day

- `./setup.sh` checks packages, configs, system files and services. It also
  notes installed packages that aren't in any list, pending `.pacnew` files,
  and Wi-Fi networks missing from the firewall's home zone.
- `./setup.sh install [step]` fixes what the check reports; `-y` skips the
  prompts. `SETUP_GROUPS="base dev" ./setup.sh install` limits it to some
  package groups.
- `./setup.sh lint` runs bash -n, shellcheck, shfmt, zsh -n, stylua and
  `qs-fmt --strict`.
- A new package goes in a list under `setup/packages/`; a new config becomes a
  top-level directory mirroring `$HOME`. Then run `./setup.sh install`.
- Hyprland and Quickshell reload when a file changes. Quickshell can miss an
  edit: [quickshell/README.md](quickshell/README.md#editing-and-hot-reload) has
  the checks.
- Logs: `journalctl --user -u <unit>` for hypridle, hyprpaper, hyprsunset and
  quickshell.

## Keys

SUPER+F1 lists every keybind, and [hypr/README.md](hypr/README.md#keybinds)
has the full table. The ones to know first:

| Keys | Does |
|---|---|
| SUPER+Return | Terminal |
| SUPER+D | App launcher |
| SUPER+E | Files |
| SUPER+B | Browser |
| SUPER+Q | Close window |
| SUPER+1 … 0 | Workspace 1 to 10; with SHIFT, send the window there |
| SUPER+V | Clipboard history |
| SUPER+Space | Switch keyboard layout (English, Arabic) |
| SUPER+SHIFT+Q | Quick settings |
| Print | Screenshot a region |
| SUPER+Escape | Lock |

## System changes

`setup.sh` copies these from `setup/system/` (they aren't links, so editing
the repo copy changes nothing until the next `./setup.sh install system`):

| File | Does |
|---|---|
| `/etc/modprobe.d/audio-powersave.conf` | Keeps the sound card powered, so audio doesn't crackle or pop when it starts. |
| `/etc/systemd/zram-generator.conf`, `/etc/sysctl.d/99-zram.conf` | Swap in compressed RAM (half its size), with the Arch wiki's sysctl values for it. |
| `/etc/mkinitcpio.conf.d/10-no-kms.conf` | The stock hooks minus `kms`, which only added about 105 MiB of firmware for nouveau; nouveau is blacklisted, and the NVIDIA driver isn't in the image. |
| `/etc/xdg/reflector/reflector.conf` | HTTPS mirrors from nearby countries, refreshed weekly by reflector.timer. |
| `/etc/firewalld/zones/home.xml` | The home zone: stock services, plus Metro for React Native (8081) and Steam Remote Play and LAN transfers. |
| `/etc/firewalld/zones/trusted.xml` | Trusts Waydroid's network bridge. |
| `/usr/local/share/wayland-sessions/hyprland.desktop` | Hides the plain Hyprland session. uwsm launches this same file, so it must keep its `Exec` line. |

It also adds a boot entry for the LTS kernel, as a fallback when an update
breaks the main one, and enables the locale in `/etc/locale.gen`.

**Firewall.** Networks use the public zone unless you trust them. Put a home
network in the home zone with
`nmcli connection modify "<name>" connection.zone home`; the zone follows the
network, not the Wi-Fi card.

**Battery.** `setup.sh` turns on UPower's charge limit, which on this laptop is
Lenovo's conservation mode: the battery stops charging before full, which
slows its wear on a laptop that mostly stays plugged in. Before a trip, charge
to full by switching it off, and back on afterwards (`./setup.sh` reports it as
missing until then):

```bash
busctl call org.freedesktop.UPower /org/freedesktop/UPower/devices/battery_BAT0 \
  org.freedesktop.UPower.Device EnableChargeThreshold b false   # b true to restore
```

## Audio

The PipeWire and WirePlumber packages hold drop-ins that change single keys.
Never copy a whole packaged config into `~/.config`: the copy stops following
the package and rots across updates.

- `default.clock.max-quantum = 8192` lets clients that ask for big buffers get
  them, which stops crackling under heavy CPU load. It's a ceiling, so
  low-latency clients still get small buffers.
- `default.clock.allowed-rates = [ 48000 44100 ]` lets PipeWire follow 44.1 kHz
  music instead of resampling it, for Bluetooth AAC and USB DACs. It doesn't
  help the laptop's speakers, which only run at 48 kHz.
- When headphones disappear mid-playback (out of range, flat battery, jack
  pulled), the fallback device is muted instead of playing on the speakers.
  Unmute when you want them.

Left at WirePlumber's defaults on purpose:

- `bluetooth.autoswitch-to-headset-profile` stays on. That's why AirPods drop
  to mono call quality whenever an app opens the microphone; turning it off
  keeps stereo but loses the Bluetooth microphone.
- `bluetooth.profile-preference` stays at quality, which prefers AAC.
- Bluetooth outputs suspend after 5 seconds of silence, which clips the start
  of the next sound. Turning that off holds the stream open and drains the
  headphones' battery; if the clipping bothers you more, add this to the
  WirePlumber drop-in:

  ```
  monitor.bluez.rules = [
    {
      matches = [ { node.name = "~bluez_output.*" } ]
      actions = { update-props = { session.suspend-timeout-seconds = 0 } }
    }
  ]
  ```

## Gaming

Set each Steam game's launch options to:

```
gamemoderun mangohud %command%
```

- **GameMode** tells the shell a game is running: it raises the power profile,
  holds notifications back, and keeps the screen from dimming while you play
  with a controller. `gamemoded -s` says whether it's active. The CPU governor
  stays at powersave on purpose: the platform profile is what raises this
  laptop's power limits and fan curve, and forcing the performance governor
  would only add heat.
- **MangoHud** starts hidden. Right Shift+F12 shows it, and Left Shift+F1
  cycles a frame cap of 60, 120 or unlimited.
- 32-bit games need `lib32-gamemode` and `lib32-mangohud`, which are in the
  package lists.
- **ProtonPlus** installs Proton-GE builds; choose one per game under
  Properties → Compatibility.

Fullscreen games skip vsync and keep the screen awake; see
[hypr/README.md](hypr/README.md#games).

## Maintenance

- **`.pacnew` files:** review them with `sudo DIFFPROG='nvim -d' pacdiff`, and
  merge rather than overwrite `pacman.conf`, `mirrorlist` and `locale.gen`.
  Overwriting them drops multilib, the mirrors and your locale. `./setup.sh`
  counts pending ones.
- **Package cache:** paccache.timer trims it weekly, keeping three versions of
  each package. `sudo paccache -ruk0` drops the cache of uninstalled packages.
- **Orphans:** read `pacman -Qdtq` before removing anything, and never pipe it
  straight into `pacman -Rns -`. Everything these configs rely on is listed and
  marked explicit, but the orphan list can still hold something you use.
- **BIOS updates:** Lenovo ships them for this model as Windows installers
  only; fwupd has none. `cat /sys/class/dmi/id/bios_version` shows the
  installed version.

## macOS

On macOS, `./setup.sh install` installs Homebrew if it's missing, runs
`brew bundle --file setup/macos/Brewfile`, and stows aerospace, bat, btop,
ghostty, gitconfig, mpv, nvim, starship and zsh. AeroSpace uses Alt where
Hyprland uses SUPER, Ghostty is the terminal, and Raycast is the launcher.

## Considered and not installed

| Tool | Why not |
|---|---|
| mise | fnm, rustup and go already manage the toolchains in use. |
| direnv | No project needs per-directory environments yet. |
| Docker, Podman | No container workflow on this machine. |
| atuin | zsh history with fzf on Ctrl+R covers it. |
| udiskie | Thunar and thunar-volman already mount drives. |
| hyprshot | The shell's screenshot service covers it. |
| nvtop | btop shows the GPU. |
| Heroic, Lutris | Steam is the only game store in use. |
| Jellyfin, Kodi | mpv and the browser cover playback. |
| LenovoLegionLinux | It needs an out-of-tree kernel module; UPower and power-profiles-daemon cover the battery and power modes. |
| qt6ct, Kvantum | Not needed for the few Qt apps here. |
| fwupd | It has no firmware for this model. |
| A clipboard panel, a workspace overview | Declined; SUPER+V and the workspace strip cover them. |
| Backups | Declined for now. The GPG signing key exists only on this machine. |

## License

[MIT](LICENSE).
