{ self, inputs, ... }: {
  flake.nixosModules.general = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.xkb
      self.nixosModules.i18n
      self.nixosModules.networking
      self.nixosModules.nix
      self.nixosModules.sddm
      self.nixosModules.hjem
    ];

    users = {
      groups.libvirtd.members = [ "${config.preferences.user.name}" ];
      users.${config.preferences.user.name} = {
        isNormalUser = true;
        shell = self.packages.${pkgs.system}.zsh;
        description = "${config.preferences.user.name}'s account";
        extraGroups = [ "networkmanager" "wheel" "dialout" "ydotool" "libvirtd" "kvm" ];
        initialPassword = "12345";
      };
    };
  };
}
