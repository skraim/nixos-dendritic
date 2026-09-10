{ self, inputs, ... }: {
  flake.nixosModules.gaming = { config, pkgs, ... }:
    {
      programs.steam.enable = true;
    };
}
