{ self, inputs, ... }: {
  flake.nixosModules.general = { self', config, ... }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.xkb
      self.nixosModules.i18n
      self.nixosModules.networking
      self.nixosModules.nix
      self.nixosModules.sddm
    ];

    users = {
      groups.libvirtd.members = [ "${config.preferences.user.name}" ];
      defaultUserShell = self'.packages.zsh;
      users.${config.preferences.user.name} = {
        isNormalUser = true;
        description = "${config.preferences.user.name}'s account";
        extraGroups = [ "networkmanager" "wheel" "dialout" "ydotool" "libvirtd" "kvm" ];
        initialPassword = "12345";
      };
    };
  };
}
