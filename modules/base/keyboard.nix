{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences.keyboard = {
      layout = lib.mkOption {
        type = lib.types.str;
        default = "us,ua-graph-rev";
      };
      options = lib.mkOption {
        type = lib.types.str;
        default = "grp:caps_toggle";
      };
    };
  };
}
