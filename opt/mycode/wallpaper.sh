#!/bin/zsh

# The idea behind this wallpaper setter is that you will see each
# wallpaper equally often, by moving all seen wallpapers into the seen
# directory. Only after all wallpapers have been seen, move them back
# in the main directory.

# For debugging
setopt local_options xtrace
exec > $HOME/.local/wallpaper.log 2>&1

# To avoid getting an error in an empty directory
setopt null_glob

#todo, require feh

PATH=/usr/local/bin:/usr/bin:/bin

WPDIR=~/Wallpapers
WPSDIR=~/Wallpapers/seen
# Deprecated? That's news to me.
local USER=$(whoami)
local ID=$(id -u)

# Test if sway is running and set the SWAYSOCK env var.
if pgrep -u $USER -x sway > /dev/null 2>&1; then
    export SWAYSOCK=/run/user/$ID/sway-ipc.$ID.$(pgrep -u $USER -x sway).sock
    # XXX, where can I find out how this should be set?
    export WAYLAND_DISPLAY='wayland-1'
else
    unset SWAYSOCK
fi

if ! i3proc=$(pgrep -f "^$(which i3)" -u $USER || pgrep -x -f i3 -u $USER); then
    unset i3proc
fi



find_wp() {
    wallpapers=($WPDIR/*.(jpg|png|webp|avif))
    if ((${#wallpapers} == 0)); then
        return 1
    fi
    ((wallpaperid = $RANDOM % ${#wallpapers} + 1))
}

set_wp_X() {
    # Set DISPLAY — This is important for cronjobs.
    eval export $(strings /proc/$i3proc/environ | grep DISPLAY=)
    feh --bg-fill -B black "${wallpapers[$wallpaperid]}"
}

set_wp_wl() {
    pkill swaybg
    sleep 0.1
    mv_wp
    # swaybg doesn't like it if it can't find the current wallpaper.
    swaybg -c '#000000' -i "$WPSDIR/${wallpapers[$wallpaperid]##*/}" &
}

set_wp() {
    # Are we running i3 on X or sway on wayland
    if [[ -n $SWAYSOCK ]]; then
        set_wp_wl
    fi
    # and what if we run both?
    if [[ -n $i3proc ]]; then
        set_wp_X
    fi
}

mv_wp() {
    [[ -d $WPSDIR ]] || { echo "$WPSDIR is not a dir. Bailing out"; exit 1}
    mv "${wallpapers[$wallpaperid]}" $WPSDIR
}

mv_wp_back() {
    if [[ $WPSDIR/*.(jpg|png|webp) == $WPSDIR/'*.(jpg|png|webp)' ]]; then
        mv $WPSDIR/*.(jpg|png|webp) $WPDIR
    else
        echo "No wallpaper found in $WPSDIR." >&2
        exit 1
    fi
}

if ! find_wp; then
    mv_wp_back
    find_wp
fi
set_wp
