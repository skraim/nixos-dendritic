{ self, inputs, ... }: {
  flake.nixosModules.hyprland = { config, pkgs, ... }: {
    programs = {
      hyprland = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.hyprlandPortal;
        xwayland.enable = true;
      };
      ydotool.enable = true;
      thunar.enable = true;
    };
    services = {
      hypridle = {
        enable = true;
        package = self.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;
      };
      kanshi.enable = true;
    };

    # systemd.user.services.hyprsunset = {
    #   description = "Hyprland blue-light filter";
    #   wantedBy = [ "graphical-session.target" ];
    #   partOf = [ "graphical-session.target" ];
    #   serviceConfig = {
    #     ExecStart = "${self.packages.${pkgs.system}.hyprsunset}/bin/hyprsunset";
    #     Restart = "on-failure";
    #   };
    # };

    hjem.users.${config.preferences.user.name} = {
      files.".config/xdg-desktop-portal/hyprland-portals.conf".text = ''
        [preferred]
        default=hyprland
        org.freedesktop.impl.portal.ScreenCast=hyprland
        org.freedesktop.impl.portal.Screenshot=hyprland
      '';
    };
  };

  perSystem = { self', pkgs, ... }: {
    packages.hyprsunset =
      let
        configDir = pkgs.writeTextDir "hypr/hyprsunset.conf" ''
          profile {
            gamma=0.800000
            identity=true
            time=7:30
          }

          profile {
            gamma=0.700000
            temperature=5000
            time=20:00
          }
          max-gamma=100
        '';
      in
      inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.hyprsunset;
        env.XDG_CONFIG_DIRS = toString configDir;
      };

    packages.hyprlandPortal =
      let
        configDir = pkgs.writeTextDir "hypr/xdph.conf" ''
          screencopy {
            cursor_mode = 2
          }
        '';
      in
      inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.xdg-desktop-portal-hyprland;
        env.XDG_CONFIG_DIRS = toString configDir;
      };

    packages.hypridle =
      (inputs.wrappers.wrapperModules.hypridle.apply {
        inherit pkgs;
        settings = {
          general = {
            after_sleep_cmd = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'";
            before_sleep_cmd = "loginctl lock-session";
            lock_cmd = "pidof hyprlock || hyprlock";
          };

          listener = [
            {
              "on-resume" = "hyprctl hyprsunset gamma 80";
              "on-timeout" = "hyprctl hyprsunset gamma 10";
              timeout = 600;
            }
            {
              "on-resume" = "hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })' && hyprctl hyprsunset gamma 80";
              "on-timeout" = "hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'";
              timeout = 900;
            }
          ];
        };
      }).wrapper;

    packages.hyprland = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.hyprland;
      flags = {
        "-c" = ./hyprland.lua;
      };
      runtimeInputs = [
        pkgs.hyprland-per-window-layout
        pkgs.hyprshutdown
        self'.packages.hyprsunset
      ];
    };
  };
}
