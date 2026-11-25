# nvidia-p2p-dkms-hook

Pacman hook that applies a P2P patch
([QuixiAI's 620-series port](https://github.com/QuixiAI/open-gpu-kernel-modules); older drivers:
[aikitoria's](https://github.com/aikitoria/open-gpu-kernel-modules))
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

`p2p.diff` = the P2P subset of the QuixiAI fork (NVIDIA base `620.70.06`): four files,
`kernel_bif.c` (force P2P caps + BAR1 P2P type), `kern_bus_gp100.c` (dispatch
`PCIE_BAR1`), `g_kern_bus_nvoc.c` (route pre-Hopper chips to the GH100 BAR1-P2P HAL)
and `nv-reg.h` (`EnableResizableBar` defaults to 1). The fork's unrelated changes
(DGX Spark memory pools, ATS faults) are left out. Applies cleanly to 620.73.04.

The old aikitoria 615 diff no longer applies on 620-series drivers (610+ has native
BAR1 P2P, so the patch is much smaller).

## Use

```sh
./install.sh             # install hook + scripts + patch
./install.sh --rebuild   # also patch current driver now and rebuild (then reboot)
nvidia-p2p-refresh             # regenerate diff (aikitoria branch, else QuixiAI fork), test it
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
