#!/usr/bin/env bash
# setup.sh - bring a machine in line with this repo: packages, configs, system
# files and services. Written for Arch Linux; on macOS it runs the Brewfile and
# stows the portable configs.
#
# Usage
#   ./setup.sh [check]               report what is missing; changes nothing
#   ./setup.sh install [-y] [step]   fix what check reports, asking per item;
#                                    -y answers yes and passes --noconfirm on
#   ./setup.sh lint                  syntax and style checks for the repo
#
# Steps, in order: multilib packages stow aur system user services
# Package groups are setup/packages/*.txt; SETUP_GROUPS picks some, e.g.
#   SETUP_GROUPS="base desktop dev" ./setup.sh install
# Exit status: 0 nothing missing, 1 something missing, 2 tooling missing.

# shellcheck disable=SC2046 # package and unit lists are split on purpose

set -Eeuo pipefail
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
trap 'echo "setup: failed at line $LINENO" >&2' ERR

mode=check yes=0 missing=0 reboot=0 steps=()
read -ra groups <<<"${SETUP_GROUPS:-base hardware desktop dev gaming apps}"

die() {
  echo "setup: $*" >&2
  exit 1
}
warn() { echo "  warn     $*"; }
run() {
  echo "    \$ $*"
  [[ $mode == check ]] || "$@"
}
confirm() {
  ((yes)) && return
  local answer
  read -rp "  fix $1? [Y/n] " answer </dev/tty || return 1
  [[ ${answer:-y} == [Yy]* ]]
}
noconfirm() { if ((yes)); then echo --noconfirm; fi; }
want() { ((${#steps[@]} == 0)) || [[ " ${steps[*]} " == *" $1 "* ]]; }

# item <label> <check> <fix>: check and fix are a function name plus plain
# arguments. In check mode the fix only prints its commands.
item() {
  if $2; then
    echo "  ok       $1"
    return
  fi
  echo "  MISSING  $1"
  if [[ $mode == check ]] || ! confirm "$1"; then
    [[ $mode == install ]] || $3
    missing=$((missing + 1))
    return
  fi
  $3
  $2 || die "$1: still missing after the fix"
}

# --- packages -----------------------------------------------------------------

list() { sed 's/#.*//; s/[[:space:]]*$//; /^$/d' "setup/packages/$1.txt"; }
listed() { for g in "${groups[@]}"; do list "$g"; done | sed 's|^aur/||' | sort -u; }
absent() { if (($#)); then pacman -T "$@" || true; fi; }
repo_missing() { absent $(list "$1" | grep -v '^aur/'); }
aur_missing() { absent $(list "$1" | sed -n 's|^aur/||p'); }

multilib_ok() { grep -q '^\[multilib\]' /etc/pacman.conf; }
multilib_add() { run sudo sed -i '/^#\[multilib\]/,/^#Include/s/^#//' /etc/pacman.conf; }

repo_ok() { [[ -z $(repo_missing "$1") ]]; }
repo_add() { run sudo pacman -Syu --needed $(noconfirm) $(repo_missing "$1"); }

as_deps() { comm -12 <(pacman -Qqd | sort) <(listed); }
reasons_ok() { [[ -z $(as_deps) ]]; }
reasons_fix() { run sudo pacman -D --asexplicit $(as_deps); }

yay_ok() { command -v yay >/dev/null; }
yay_get() { run bash -c 'd=$(mktemp -d) && git clone -q --depth 1 https://aur.archlinux.org/yay.git "$d" && cd "$d" && makepkg -si --noconfirm'; }
yay_tidy_ok() { yay -Pg 2>/dev/null | grep -q '"cleanAfter": true'; }
yay_tidy() { run yay --save --cleanafter --removemake; }
aur_ok() { [[ -z $(aur_missing "$1") ]]; }
aur_add() { run yay -S --needed $(noconfirm) $(aur_missing "$1"); }

# --- configs ------------------------------------------------------------------

packages() { for d in */; do [[ $d == setup/ ]] || echo "${d%/}"; done; }
stow_pending() { stow -n -v -d "$PWD" -t "$HOME" -S "$@" 2>&1 | grep -v '^WARNING: in simulation mode' || true; }
stowed() { [[ -z $(stow_pending $(packages)) && -d ~/.config/systemd/user && ! -L ~/.config/systemd/user ]]; }
stow_all() {
  [[ $mode == install ]] || stow_pending $(packages) | sed 's/^/      /'
  # A real directory, so `systemctl --user enable` never writes into the repo.
  run mkdir -p "$HOME/.config/systemd/user"
  run stow -d "$PWD" -t "$HOME" -S $(packages) ||
    die "move the conflicting files aside, or stow --adopt them and review with git diff"
}

# --- system -------------------------------------------------------------------

sys_stale() { for f in $(find setup/system -type f | sort); do cmp -s "$f" "/${f#setup/system/}" || echo "$f"; done; }
sys_ok() { [[ -z $(sys_stale) ]]; }
sys_install() {
  local f initramfs=0 sysctl=0 firewall=0
  for f in $(sys_stale); do
    run sudo install -b -Dm644 "$f" "/${f#setup/system/}"
    case $f in
      */mkinitcpio.conf.d/*) initramfs=1 ;;
      */sysctl.d/*) sysctl=1 ;;
      */firewalld/*) firewall=1 ;;
      */modprobe.d/* | */zram-generator.conf) reboot=1 ;;
    esac
  done
  if ((initramfs)); then run sudo mkinitcpio -P; fi
  if ((sysctl)); then run sudo sysctl --system; fi
  if ((firewall)) && systemctl is-active -q firewalld; then run sudo firewall-cmd --reload; fi
}

# systemd-boot has no entry for linux-lts until one is written; copy the
# linux entry's options, which carry this machine's root partition.
lts_ok() { [[ ! -e /boot/vmlinuz-linux-lts ]] || grep -qs 'vmlinuz-linux-lts' /boot/loader/entries/*.conf; }
lts_add() {
  local src
  src=$(grep -ls 'vmlinuz-linux$' /boot/loader/entries/*.conf | head -1) || true
  [[ -n $src ]] || die "no systemd-boot entry for vmlinuz-linux to copy"
  run sudo sh -c "sed -e 's/^title .*/title Arch Linux (LTS)/' -e 's/vmlinuz-linux\$/vmlinuz-linux-lts/' -e 's/initramfs-linux\.img/initramfs-linux-lts.img/' '$src' > /boot/loader/entries/arch-lts.conf"
}

# --- user ---------------------------------------------------------------------

gamemode_ok() { id -nG | grep -qw gamemode; }
gamemode_join() { run sudo usermod -aG gamemode "$USER"; }
zsh_ok() { [[ $(getent passwd "$USER" | cut -d: -f7) == */zsh ]]; }
zsh_use() { run chsh -s /usr/bin/zsh; }
gtk_ok() { ! grep -qvxFf <(dconf dump /org/gnome/desktop/interface/) setup/dconf/interface.ini; }
gtk_set() { run sh -c 'dconf load /org/gnome/desktop/interface/ < setup/dconf/interface.ini'; }
home_dirs=(TEMPLATES PUBLICSHARE MUSIC VIDEOS)
dirs_ok() {
  local d p
  for d in "${home_dirs[@]}"; do
    p=$(xdg-user-dir "$d")
    [[ ${p%/} == "$HOME" ]] || return 1
  done
}
dirs_set() { for d in "${home_dirs[@]}"; do run xdg-user-dirs-update --set "$d" "$HOME"; done; }

battery=/org/freedesktop/UPower/devices/battery_BAT0
upower_prop() { busctl get-property org.freedesktop.UPower "$battery" org.freedesktop.UPower.Device "$1" 2>/dev/null || true; }
charge_ok() { [[ $(upower_prop ChargeThresholdSupported) != "b true" || $(upower_prop ChargeThresholdEnabled) == "b true" ]]; }
charge_cap() { run busctl call org.freedesktop.UPower "$battery" org.freedesktop.UPower.Device EnableChargeThreshold b true; }

walls_ok() { compgen -G "$HOME/Pictures/Wallpapers/*" >/dev/null; }
walls_seed() { run install -Dm644 hypr/.config/hypr/wallpaper.jpg "$HOME/Pictures/Wallpapers/wallpaper.jpg"; }
rust_ok() { ! command -v rustup >/dev/null || rustup default >/dev/null 2>&1; }
rust_set() { run rustup default stable; }
ext_missing() { comm -23 <(sort setup/packages/code-extensions.txt) <(code --list-extensions 2>/dev/null | sort); }
ext_ok() { ! command -v code >/dev/null || [[ -z $(ext_missing) ]]; }
ext_add() { for e in $(ext_missing); do run code --install-extension "$e"; done; }

# --- services -----------------------------------------------------------------

sc() { if [[ $1 == user ]]; then systemctl --user "${@:2}"; else systemctl "${@:2}"; fi; }
unit_ok() { sc "$1" is-enabled -q "$2"; }
unit_on() { if [[ $1 == user ]]; then run systemctl --user enable "$2"; else run sudo systemctl enable "$2"; fi; }

# --- commands -----------------------------------------------------------------

lint() {
  local f rc=0 sh=(setup.sh quickshell/.config/quickshell/qs-fmt)
  for f in shellcheck shfmt stylua zsh; do
    command -v $f >/dev/null || {
      echo "setup: lint needs $f" >&2
      exit 2
    }
  done
  for f in "${sh[@]}"; do bash -n "$f" || rc=1; done
  shellcheck "${sh[@]}" || rc=1
  shfmt -d -i 2 -ci "${sh[@]}" || rc=1
  for f in zsh/.zshenv zsh/.config/zsh/.zshrc zsh/.config/zsh/*.zsh zsh/.config/zsh/core/*.zsh; do zsh -n "$f" || rc=1; done
  stylua --check --search-parent-directories nvim hypr || rc=1
  quickshell/.config/quickshell/qs-fmt --strict >/dev/null || rc=1
  return $rc
}

mac() {
  brew_ok() { command -v brew >/dev/null; }
  brew_get() { run bash -c 'bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'; }
  bundle_ok() { brew bundle check --file setup/macos/Brewfile >/dev/null 2>&1; }
  bundle_run() { run brew bundle --file setup/macos/Brewfile; }
  portable() { for p in zsh starship nvim alacritty gitconfig ghostty bat lazygit; do if [[ -d $p ]]; then echo "$p"; fi; done; }
  mac_stowed() { [[ -z $(stow_pending $(portable)) ]]; }
  mac_stow() { run stow -d "$PWD" -t "$HOME" -S $(portable); }

  echo macOS
  item Homebrew brew_ok brew_get
  item Brewfile bundle_ok bundle_run
  item configs mac_stowed mac_stow
}

case ${1:-check} in
  check) ;;
  install)
    mode=install
    shift
    for a; do if [[ $a == -y ]]; then yes=1; else steps+=("$a"); fi; done
    ;;
  lint) if lint; then exit 0; else exit 1; fi ;;
  -h | --help)
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
    exit 0
    ;;
  *) die "unknown command $1 (try --help)" ;;
esac

if [[ $(uname -s) == Darwin ]]; then
  mac
else
  [[ -e /etc/arch-release ]] || die "this is for Arch Linux and macOS"
  ((EUID != 0)) || die "run it as your user; it uses sudo where needed"
  [[ $mode == check ]] || sudo -v

  if want multilib; then
    echo multilib
    item "[multilib] in pacman.conf" multilib_ok multilib_add
  fi
  if want packages; then
    echo packages
    for g in "${groups[@]}"; do item "$g" "repo_ok $g" "repo_add $g"; done
    item "listed packages marked explicit" reasons_ok reasons_fix
  fi
  if want stow; then
    echo stow
    item "configs stowed into ~" stowed stow_all
  fi
  if want aur; then
    echo aur
    item yay yay_ok yay_get
    item "yay cleans up after builds" yay_tidy_ok yay_tidy
    for g in "${groups[@]}"; do
      if list "$g" | grep -q '^aur/'; then item "$g (AUR)" "aur_ok $g" "aur_add $g"; fi
    done
  fi
  if want system; then
    echo system
    item "setup/system files in place" sys_ok sys_install
    item "boot entry for linux-lts" lts_ok lts_add
  fi
  if want user; then
    echo user
    item "in the gamemode group" gamemode_ok gamemode_join
    item "zsh as login shell" zsh_ok zsh_use
    item "GTK settings" gtk_ok gtk_set
    item "Templates, Public, Music, Videos point at ~" dirs_ok dirs_set
    item "battery charge limit" charge_ok charge_cap
    item "a wallpaper in ~/Pictures/Wallpapers" walls_ok walls_seed
    item "rust toolchain" rust_ok rust_set
    item "Code - OSS extensions" ext_ok ext_add
    key=$(git config --get user.signingkey || true)
    [[ -z $key ]] || gpg --list-secret-keys "$key" >/dev/null 2>&1 ||
      warn "signing key $key is not in gpg; commits are signed, so import it"
    compgen -G "$HOME/.ssh/id_*.pub" >/dev/null || warn "no SSH key in ~/.ssh; GitHub pushes go over SSH"
  fi
  if want services; then
    echo services
    mapfile -t units < <(sed 's/#.*//' setup/services.txt | awk 'NF == 2')
    for u in "${units[@]}"; do
      read -r scope unit <<<"$u"
      if sc "$scope" cat "$unit" >/dev/null 2>&1; then
        item "$unit" "unit_ok $scope $unit" "unit_on $scope $unit"
      else
        warn "$unit is not installed"
      fi
    done
  fi

  echo
  [[ -n ${SETUP_GROUPS:-} ]] || {
    extra=$(comm -23 <(pacman -Qqe | sort) <(listed) | tr '\n' ' ')
    [[ -z $extra ]] || warn "installed but not in setup/packages: $extra"
  }
  pacnew=$(find /etc -name '*.pacnew' 2>/dev/null | wc -l || true)
  ((pacnew == 0)) || warn "$pacnew .pacnew file(s) in /etc; merge them with sudo pacdiff"
fi

if ((reboot)) && [[ $mode == install ]]; then echo "reboot to apply the modprobe and zram changes"; fi
if ((missing)); then
  echo "$missing item(s) missing"
  exit 1
fi
echo "everything is in place"
