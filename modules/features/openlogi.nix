{ self, inputs, ... }: {
  flake.nixosModules.openlogi = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.openlogi
    ];
  };
}
