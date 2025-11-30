#!/bin/zsh
release=$(rpm -E %fedora)
release=$((release + 1))
if [[ $release -gt 43 ]]; then
    echo "Fedora Release $release is not yet available." >&2
    exit 1
fi

if ! whoami | grep -q '^root$'; then
    echo "Run this program as root (sudo -i)." >&2
    exit 1
fi

if [[ -z  $TMUX ]]; then
    echo "Run this program from a tmux session." >&2
    exit 1
fi

dnf -y upgrade --refresh
dnf -y system-upgrade download --releasever=$release

echo "Ready for reboot, press the any key to continue."
read -sk1 niets

if [[ -x /usr/bin/dnf5 ]]; then
    dnf5 -y offline reboot
else
    dnf -y system-upgrade reboot
fi
