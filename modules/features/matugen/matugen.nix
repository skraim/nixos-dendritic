{ self, inputs, ... }: {
  flake.nixosModules.matugen = { config, pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.matugen
    ];
  };

  perSystem = { self', pkgs, ... }:
    let
      matugenConfig = (pkgs.formats.toml {}).generate "matugen-config.toml" {
        config = {
          wallpaper = {
            set = true;
            command = "awww img {{ image }}";
          };
        };

        templates = {
          hypr = {
            input_path = "${./templates/hyprland-colors.lua}";
            output_path = "~/.config/hypr/colors.lua";
          };
          kitty = {
            input_path = "${./templates/kitty-colors.conf}";
            output_path = "~/.config/kitty/background-color.conf";
            post_hook = "pkill -SIGUSR1 kitty";
          };
          quickshell = {
            input_path = "${./templates/quickshell-colors.json}";
            output_path = "~/.cache/quickshell/colors.json";
          };
          yazi = {
            input_path = "${./templates/yazi-theme.toml}";
            output_path = "~/.config/yazi/theme.toml";
          };
        };
      };
    in {

      packages.matugen = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.matugen;
        flags = {
          "-c" = matugenConfig;
        };
        # runtimeInputs = [
        #   self'.packages.hyprsunset
        #   pkgs.hyprland-per-window-layout
        #   inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
        # ];
      };
    };
}
