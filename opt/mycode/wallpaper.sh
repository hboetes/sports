#!/bin/zsh

# Wallpaper Setter Script
# Cycles through wallpapers ensuring equal viewing frequency by moving seen
# wallpapers to a separate directory. Once all wallpapers are seen, they're
# moved back.

set -euo pipefail
setopt null_glob nocaseglob

# Configuration
readonly WPDIR=${HOME}/Wallpapers
readonly WPSDIR=${WPDIR}/seen
readonly LOG_FILE=${HOME}/.local/log/wallpaper.log
readonly IMG_PATTERN='*.(jpg|png|webp|avif)'

# For debugging
setopt local_options xtrace
exec > "${LOG_FILE}" 2>&1

# Environment setup
readonly USER=$(whoami)
readonly ID=$(id -u)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/${ID}}
export PATH=/usr/local/bin:/usr/bin:/bin

# --------------------------------------------------------------------------- #
# Helpers
# --------------------------------------------------------------------------- #

die() { echo "Error: $*" >&2; exit 1; }

# Scrape WAYLAND_DISPLAY from any process owned by $USER, verifying the socket
# exists to avoid stale values (e.g. emacs daemon from a previous session).
# Sets WAYLAND_DISPLAY directly via typeset -g; returns 1 if not found.
# Avoids command substitution to prevent xtrace output pollution.
find_wayland_display() {
    local envfile val result
    for envfile in /proc/*/environ; do
        [[ $(stat -c%U "$envfile" 2>/dev/null) == "$USER" ]] || continue
        val=$(tr '\0' '\n' < "$envfile" 2>/dev/null | grep "^WAYLAND_DISPLAY=") || continue
        [[ -n "$val" ]] || continue
        result=${val#WAYLAND_DISPLAY=}
        [[ -S "${XDG_RUNTIME_DIR}/${result}" ]] || continue
        typeset -g WAYLAND_DISPLAY=$result
        export WAYLAND_DISPLAY
        return 0
    done
    return 1
}

check_dependencies() {
    local deps=(swaybg feh)
    for dep in "${deps[@]}"; do
        command -v "${dep}" >/dev/null 2>&1 || die "Required dependency '${dep}' not found"
    done
}

# --------------------------------------------------------------------------- #
# Environment detection
# --------------------------------------------------------------------------- #

detect_environment() {
    # Niri: uses a named socket, derive display name from it
    for sock in "${XDG_RUNTIME_DIR}"/niri.wayland-*.sock; do
        [[ -S "$sock" ]] || continue
        local base=${sock##*/niri.}
        export WAYLAND_DISPLAY=${base%.sock}
        return
    done

    # Sway
    if pgrep -u "${USER}" -x sway >/dev/null 2>&1; then
        local sway_pid
        sway_pid=$(pgrep -u "${USER}" -x sway)
        export SWAYSOCK=${XDG_RUNTIME_DIR}/sway-ipc.${ID}.${sway_pid}.sock
        find_wayland_display || export WAYLAND_DISPLAY=wayland-1
        return
    fi

    # MangoWC (mango)
    if pgrep -u "${USER}" -x mango >/dev/null 2>&1; then
        find_wayland_display || export WAYLAND_DISPLAY=wayland-0
        return
    fi

    # Hyprland
    local hyprland_bin
    hyprland_bin=$(command -v Hyprland 2>/dev/null) || true
    if [[ -n "$hyprland_bin" ]] && pgrep -u "${USER}" -f "$hyprland_bin" >/dev/null 2>&1; then
        export SWAYSOCK=/dev/null
        export WAYLAND_DISPLAY=$(hyprctl instances | awk -F: '/socket/ {sub(/^ +/, "", $2); print $2}')
        return
    fi

    # i3 (X11)
    I3_PROC=$(pgrep -u "${USER}" -f "^$(command -v i3 2>/dev/null)" 2>/dev/null \
              || pgrep -u "${USER}" -x i3 2>/dev/null \
              || true)
}

# --------------------------------------------------------------------------- #
# Wallpaper management
# --------------------------------------------------------------------------- #

find_wallpaper() {
    local -a wallpapers
    wallpapers=("${WPDIR}"/${~IMG_PATTERN})
    (( ${#wallpapers} > 0 )) || return 1
    wallpaper=${wallpapers[$((RANDOM % ${#wallpapers} + 1))]}
}

move_wallpaper() {
    [[ -d "${WPSDIR}" ]] || die "${WPSDIR} is not a directory"
    mv "${wallpaper}" "${WPSDIR}"
}

move_wallpapers_back() {
    local -a seen
    seen=("${WPSDIR}"/${~IMG_PATTERN})
    (( ${#seen} > 0 )) || die "No wallpapers found in ${WPSDIR}"
    mv "${WPSDIR}"/${~IMG_PATTERN} "${WPDIR}"
}

# --------------------------------------------------------------------------- #
# Wallpaper setters
# --------------------------------------------------------------------------- #

set_wallpaper_wayland() {
    pkill swaybg || true
    sleep 0.1
    move_wallpaper
    swaybg -m fill -c '#000000' -i "${WPSDIR}/${wallpaper##*/}" &
}

set_wallpaper_x11() {
    eval export "$(strings /proc/${I3_PROC}/environ | grep ^DISPLAY=)"
    feh --bg-fill -B black "${wallpaper}"
}

set_wallpaper_gnome() {
    move_wallpaper
    gsettings set org.gnome.desktop.background picture-uri-dark \
        "file://${WPSDIR}/${wallpaper##*/}"
}

set_wallpaper() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        set_wallpaper_wayland
    elif [[ -n "${I3_PROC:-}" ]]; then
        set_wallpaper_x11
    elif pgrep -f /usr/bin/gnome-shell >/dev/null 2>&1; then
        set_wallpaper_gnome
    else
        die "No supported desktop environment detected"
    fi
}

# --------------------------------------------------------------------------- #
# Main
# --------------------------------------------------------------------------- #

main() {
    check_dependencies
    detect_environment

    if ! find_wallpaper; then
        move_wallpapers_back
        find_wallpaper || die "No wallpapers found in either directory"
    fi

    set_wallpaper
}

main "$@"
