{ self, inputs, ... }: {
  flake.nixosModules.virtualisation = { config, pkgs, ... }:
    let
      user = config.preferences.user.name;
    in {
      virtualisation = {
        spiceUSBRedirection.enable = true;
        libvirtd = {
          enable = true;
          qemu.runAsRoot = false;
        };
      };

      programs.virt-manager.enable = true;

      users = {
        groups.libvirtd.members = [ "${user}" ];
        users.${user} = {
          extraGroups = [ "libvirtd" "kvm" ];
        };
      };

      environment.systemPackages = with pkgs; [
        virt-viewer
      ];
    };
}
