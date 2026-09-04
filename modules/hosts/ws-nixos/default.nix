{ self, inputs, ... }: {
  flake.nixosConfigurations.workstationNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.workstationNixosConfiguration
    ];
  };
}
