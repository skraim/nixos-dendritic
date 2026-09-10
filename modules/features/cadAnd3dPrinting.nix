{ self, inputs, ... }: {
  flake.nixosModules.cadAnd3dPrinting = { config, pkgs, ... }: {
    hardware.spacenavd.enable = true;

    environment.systemPackages = with pkgs; [
      spnavcfg
    ];
  };
}
