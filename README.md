# NixOS router

## Hardware

- Raspberry Pi Compute Module 4
- TODO ethernet board

## Build initial SD-card image

```bash
nix build .#raspi-image
sudo dd if=result/sd-image/raspi-image-...-aarch64-linux.img of=/dev/sdX status=progress bs=4M oflag=sync
```
## Update config

```bash
nixos-rebuild switch --flake '.#nixos-router' --target-host 'root@192.182.X.X' -L
```
