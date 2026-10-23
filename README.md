# nvidia-p2p-dkms-hook

Pacman hook that applies [aikitoria's P2P patch](https://github.com/aikitoria/open-gpu-kernel-modules)
to Arch's `nvidia-open-dkms` sources on every install/upgrade, before DKMS builds them.
Enables GPU-to-GPU P2P over PCIe BAR1 on GeForce RTX 30/40/50 cards.

## How it works

`-Syu` / `paru` installs `/usr/src/nvidia-<ver>/` →
`60-nvidia-p2p.hook` runs `nvidia-p2p-apply` (patches the tree) →
Arch's `70-dkms-*` hooks build the modules → mkinitcpio rebuilds the initramfs.

- Patch already applied: skipped.
- Patch does not apply to a new driver: tree stays **stock** (no P2P), warning in
  pacman output and `/var/log/nvidia-p2p.log`. The transaction never fails.
- Kernel upgrades: DKMS rebuilds from the patched tree.

## Files

| repo | installed to |
|---|---|
| `hooks/60-nvidia-p2p.hook` | `/etc/pacman.d/hooks/` |
| `bin/nvidia-p2p-apply` | `/usr/local/bin/` |
| `bin/nvidia-p2p-refresh` | `/usr/local/bin/` |
| `patch/p2p.diff`, `patch/SOURCE` | `/etc/nvidia-p2p/` |

`p2p.diff` = `aikitoria/615.71.09-p2p` vs NVIDIA tag `615.71.09` (minus README,
install.sh, patch-libcuda-p2p.py). Applies cleanly to 615.78.08.

## Use

```sh
./install.sh             # install hook + scripts + patch
./install.sh --rebuild   # also patch current driver now and rebuild (then reboot)
nvidia-p2p-refresh             # regenerate diff from newest aikitoria branch, test it
nvidia-p2p-refresh --install   # ...and install + rebuild
nvidia-smi topo -p2p r         # OK = P2P enabled, GNS = blocked
```

## Requirements

- Resizable BAR active with BAR1 ≥ VRAM (`nvidia-smi -q | grep -A1 BAR1`).
  RTX 3090s may need a ReBAR vBIOS; on ASUS boards Above 4G on **and CSM off**.
- IOMMU passthrough: `amd_iommu=on iommu=pt` (removes DMA isolation).

## Pitfall

`dkms install --force` reinstalls the cached build and does **not** recompile.
Use `dkms build --force` first (the scripts do). `nvidia` is in mkinitcpio
`MODULES=`, so run `mkinitcpio -P` after a manual rebuild.

## License

Scripts and hook: MIT (see `LICENSE`). `patch/p2p.diff` stays under the
upstream NVIDIA open-gpu-kernel-modules dual MIT/GPLv2 terms.
