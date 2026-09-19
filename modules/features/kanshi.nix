{ self, inputs, ... }: {
  flake.nixosModules.kanshi = { config, pkgs, ... }: {
    services.kanshi = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.kanshi;
    };
  };

  perSystem = {pkgs, ...}: let
    dockedMonitorSetup = pkgs.writeShellScript "kanshi-docked-monitor-setup" ''
      line=$(awww query | grep -m1 "eDP-1")
      path=''${line##*image:}
      hyprctl dispatch 'hl.dsp(hl.monitor({ output="eDP-1", mode="1920x1200@100Hz", position="0x0", scale = 1.2 }))'
      [ "$path" != "$line" ] && [ -n "$path" ] && awww img "''${path# }"
    '';
  in {
    # todo: replace hardcoded monitor data (use ./base./*)
    packages.kanshi =
      (inputs.wrappers.wrapperModules.kanshi.apply {
        inherit pkgs;
        configFile.content = ''
          profile undocked {
            output "eDP-1"
            exec hyprctl dispatch 'hl.dsp(hl.monitor({ output="eDP-1", mode="1920x1200@100Hz", position="0x0", scale = 1 }))'
          }

          profile docked {
            output "eDP-1"
            output "*"
            exec ${dockedMonitorSetup}
          }
        '';
      }).wrapper;
  };
}
