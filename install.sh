#!/usr/bin/env bash
# Install the hook, scripts and current patch onto this system.
#   ./install.sh            install files only
#   ./install.sh --rebuild  also patch /usr/src now, rebuild DKMS + initramfs
set -euo pipefail
cd "$(dirname "$0")"
sudo install -Dm644 hooks/60-nvidia-p2p.hook /etc/pacman.d/hooks/60-nvidia-p2p.hook
sudo install -Dm755 bin/nvidia-p2p-apply   /usr/local/bin/nvidia-p2p-apply
sudo install -Dm755 bin/nvidia-p2p-refresh /usr/local/bin/nvidia-p2p-refresh
sudo install -Dm644 patch/p2p.diff /etc/nvidia-p2p/p2p.diff
sudo install -Dm644 patch/SOURCE   /etc/nvidia-p2p/SOURCE
echo ":: installed"
if [ "${1:-}" = --rebuild ]; then
    sudo /usr/local/bin/nvidia-p2p-apply
    tree=$(ls -d /usr/src/nvidia-* | sort -V | tail -1); v=${tree#/usr/src/nvidia-}
    for k in /usr/lib/modules/*/build; do k=${k%/build}; k=${k##*/}
        sudo dkms build --force "nvidia/$v" -k "$k" && sudo dkms install --force "nvidia/$v" -k "$k"
    done
    sudo mkinitcpio -P
    echo ":: rebuilt; reboot to load"
fi
