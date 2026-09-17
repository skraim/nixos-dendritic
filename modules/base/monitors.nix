{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.monitors = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
          width = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 1920;
          };
          height = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 1080;
          };
          refreshRate = lib.mkOption {
            type = lib.types.number;
            default = 60;
          };
          x = lib.mkOption {
            type = lib.types.int;
            default = 0;
          };
          y = lib.mkOption {
            type = lib.types.int;
            default = 0;
          };
          scale = lib.mkOption {
            type = lib.types.str;
            default = "auto";
          };
        };
      });
      default = {};
    };
  };
}
