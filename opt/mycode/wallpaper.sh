#!/bin/zsh

# Wallpaper Setter Script
# Cycles through wallpapers ensuring equal viewing frequency by moving seen wallpapers
# to a separate directory. Once all wallpapers are seen, they're moved back.

# Strict error handling
set -euo pipefail

# Configuration
readonly WPDIR=${HOME}/Wallpapers
readonly WPSDIR=${WPDIR}/seen
readonly LOG_FILE=${HOME}/.local/log/wallpaper.log
readonly IMG_PATTERN='*.(jpg|png|webp|avif)'

# For debugging
setopt local_options xtrace
exec > "${LOG_FILE}" 2>&1

# Shell options
setopt null_glob nocaseglob

# Environment setup
readonly USER=$(whoami)
readonly ID=$(id -u)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/${ID}}
export PATH=/usr/local/bin:/usr/bin:/bin

# Check required dependencies
check_dependencies() {
    local deps=(feh swaybg)
    for dep in "${deps[@]}"; do
        if ! command -v "${dep}" >/dev/null 2>&1; then
            echo "Error: Required dependency '${dep}' not found" >&2
            exit 1
        fi
    done
}

# Desktop environment detection
detect_environment() {
    # Sway detection
    if pgrep -u "${USER}" -x sway >/dev/null 2>&1; then
        export SWAYSOCK=/run/user/${ID}/sway-ipc.${ID}.$(pgrep -u "${USER}" -x sway).sock
        export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-wayland-1}
        return
    else
        unset SWAYSOCK
    fi

    # Hyprland detection
    if pgrep -u "${USER}" -f "$(command -v Hyprland)" >/dev/null 2>&1; then
        export SWAYSOCK=/dev/null
        [[ -z ${WAYLAND_DISPLAY:-} ]] && export WAYLAND_DISPLAY=$(hyprctl instances | awk -F: '/socket/ {sub(/^ +/, "", $2); print $2}')
        return
    fi

    # i3 detection
    I3_PROC=$(pgrep -u "${USER}" -f "^$(command -v i3)" || pgrep -x -f i3 -u "${USER}" || true)
}

find_wallpaper() {
    local -a wallpapers
    wallpapers=("${WPDIR}"/${~IMG_PATTERN})

    if (( ${#wallpapers} == 0 )); then
        return 1
    fi

    wallpaper=${wallpapers[$((RANDOM % ${#wallpapers} + 1))]}
    return 0
}

set_wallpaper_x11() {
    eval export "$(strings /proc/${I3_PROC}/environ | grep DISPLAY=)"
    feh --bg-fill -B black "${wallpaper}"
}

set_wallpaper_wayland() {
    pkill swaybg || true
    sleep 0.1
    move_wallpaper
    swaybg -c '#000000' -i "${WPSDIR}/${wallpaper##*/}" &
}

set_wallpaper_gnome() {
    move_wallpaper
    gsettings set org.gnome.desktop.background picture-uri-dark "file://${WPSDIR}/${wallpaper##*/}"
}

set_wallpaper() {
    # Check for each environment and set accordingly
    if pgrep -f /usr/bin/gnome-shell >/dev/null 2>&1; then
        set_wallpaper_gnome
        return
    fi

    [[ -n ${SWAYSOCK:-} ]] && set_wallpaper_wayland
    [[ -n ${I3_PROC:-} ]] && set_wallpaper_x11
}

move_wallpaper() {
    if [[ ! -d ${WPSDIR} ]]; then
        echo "Error: ${WPSDIR} is not a directory" >&2
        exit 1
    fi
    mv "${wallpaper}" "${WPSDIR}"
}

move_wallpapers_back() {
    local -a seen_wallpapers
    seen_wallpapers=("${WPSDIR}"/${~IMG_PATTERN})

    if (( ${#seen_wallpapers} > 0 )); then
        mv "${WPSDIR}"/${~IMG_PATTERN} "${WPDIR}"
    else
        echo "No wallpapers found in ${WPSDIR}" >&2
        exit 1
    fi
}

main() {
    check_dependencies
    detect_environment

    if ! find_wallpaper; then
        move_wallpapers_back
        find_wallpaper || {
            echo "Error: No wallpapers found in either directory" >&2
            exit 1
        }
    fi

    set_wallpaper
}

main "$@"
