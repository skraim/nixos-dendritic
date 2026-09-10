{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.vpns = {
      snx = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      sc = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      ts = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
    };
  };
}
