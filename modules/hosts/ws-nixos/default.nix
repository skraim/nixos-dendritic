{ self, inputs, ... }: {
  flake.nixosConfigurations.workstationNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.workstationNixosConfiguration
      inputs.sops-nix.nixosModules.sops
    ];
  };
}
