{ self, inputs, ... }: {
  flake.nixosConfigurations.playstationNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.playstationNixosConfiguration
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
    ];
  };
}
