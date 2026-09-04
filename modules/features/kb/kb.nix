{ self, inputs, ... }: {
  flake.nixosModules.xkb = { config, ... }: let
    layout = config.preferences.keyboard.layout;
    options = config.preferences.keyboard.options;
  in {
    services = {
      xserver = {
        xkb = {
          layout = "${layout}";
          options = "${options}";
          variant = "";
          extraLayouts = {
            ua-graph-rev = {
              description = "UA Graphite reverse";
              symbolsFile = ./ua-graph-rev;
              languages = [ "ua" ];
            };
          };
        };
      };
    };

    console.keyMap = "uk";
  };
}
