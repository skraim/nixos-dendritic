# Playstation disko install cmd
```bash
sudo nix --extra-experimental-features "nix-command flakes" \
         run 'github:nix-community/disko/latest#disko-install' -- \
         --flake .#playstationNixos \
         --disk main /dev/disk/by-id/nvme-KINGSTON_SKC2500M8500G_50026B72825CF846
 ```

# Workstation disko install cmd
```bash
sudo nix --extra-experimental-features "nix-command flakes" \
  run 'github:nix-community/disko/latest#disko-install' -- \
  --flake .#workstationNixos \
  --disk main /dev/disk/by-id/nvme-WD_PC_SN810_SDCPNRY-1T00-1006_224650802469
```
