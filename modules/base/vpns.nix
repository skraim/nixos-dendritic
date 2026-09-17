{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.vpns = {
      ts = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    };
  };
}
