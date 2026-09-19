{ self, inputs, ... }: {
  flake.nixosConfigurations.workstationNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.workstationNixosConfiguration
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.default
    ];
  };
}
