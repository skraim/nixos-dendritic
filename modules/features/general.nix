{ self, inputs, ... }: {
  flake.nixosModules.general = { self', config }: {
    imports = [
      self.nixosModules.base
      self.nixosModules.xkb
      self.nixosModules.i18n
      self.nixosModules.networking
      self.nixosModules.nix
    ];

    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = ["wheel" "networkmanager"];
      shell = self'.packages.zsh; #environment;

      hashedPasswordFile = "/persist/passwd";
      initialPassword = "12345";
    };

  };
}
