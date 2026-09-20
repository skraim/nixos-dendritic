{...}: {
  flake.nixosModules.preservation = {
    config,
    pkgs,
    ...
  }: {
    boot = {
      initrd = {
        supportedFilesystems = ["btrfs"];

        systemd.services.rollback-root = {
          description = "Recreate ephemeral Btrfs root";
          wantedBy = ["initrd.target"];
          requires = ["initrd-root-device.target"];
          after = ["initrd-root-device.target"];
          before = ["sysroot.mount"];

          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";
          path = with pkgs; [
            btrfs-progs
            coreutils
            util-linux
          ];
          script = ''
            mountpoint=/btrfs-toplevel
            mkdir -p "$mountpoint"
            mount -o subvolid=5 ${config.fileSystems."/".device} "$mountpoint"

            if [ -e "$mountpoint/@root" ]; then
              btrfs subvolume delete -R "$mountpoint/@root"
            fi
            btrfs subvolume create "$mountpoint/@root"

            umount "$mountpoint"
          '';
        };
      };
    };

    preservation = {
      enable = true;

      preserveAt."/persistent" = {
        directories = [
          {
            directory = "/var/lib/nixos";
            inInitrd = true;
          }
          "/etc/nixos"
          "/var/lib/bluetooth"
          "/var/lib/systemd/timers"
          "/etc/NetworkManager/system-connections"
        ];

        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];

        users.${config.preferences.user.name} = {
          directories = [
            "pictures"
            "projects"
            "music"
            "videos"
            "documents"

            "nixos"
            ".cache/quickshell"
            ".local/share/nvim"
            ".password-store"
            ".ssh"
            {
              directory = ".gnupg";
              mode = "0700";
            }
          ];

          files = [
            ".zsh_history"
            ".config/hypr/colors.lua"
            ".config/kitty/background-color.conf"
            ".config/kitty/current-theme.conf"
          ];
        };
      };
    };

    systemd.services."systemd-machine-id-commit".enable = false;
    fileSystems."/nix".neededForBoot = true;
    fileSystems."/persistent".neededForBoot = true;
  };
}
