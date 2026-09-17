{ self, inputs, ... }: {
  flake.nixosConfigurations.playstationNixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.playstationNixosConfiguration
      inputs.sops-nix.nixosModules.sops
      inputs.nix-index-database.nixosModules.default
    ];
  };
}
