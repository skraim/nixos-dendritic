{
  flake.diskoConfigurations.workstationNixos = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/nvme-WD_PC_SN810_SDCPNRY-1T00-1006_224650802469";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = ["umask=0077"];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                    };
                    "@nix" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/nix";
                    };
                    "@persistent" = {
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                      mountpoint = "/persistent";
                    };
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap = {
                        swapfile.size = "34G";
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
