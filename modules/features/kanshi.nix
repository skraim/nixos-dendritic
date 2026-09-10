{ self, inputs, ... }: {
  flake.nixosModules.kanshi = { config, pkgs, ... }: {
    services.kanshi = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.kanshi;
    };
  };

  perSystem = {pkgs, ...}: {
    # todo: replace hardcoded monitor data (use ./base./*)
    packages.kanshi =
      (inputs.wrappers.wrapperModules.kanshi.apply {
        inherit pkgs;
        configFile.content = ''
          profile undocked {
            output "eDP-1"
            exec hyprctl keyword monitor "eDP-1,1920x1200,0x0,1"
          }

          profile docked {
            output "eDP-1"
            output "*"
            exec bash -c '
              line=$(awww query | grep -m1 "eDP-1")
              path=''${line##*image:}
              hyprctl keyword monitor "eDP-1,1920x1200,0x0,1.2"
              [ "$path" != "$line" ] && [ -n "$path" ] && awww img "''${path# }"
            '
          }
        '';
      }).wrapper;
  };
}
