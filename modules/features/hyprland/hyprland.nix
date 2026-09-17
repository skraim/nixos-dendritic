{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.hyprland = {
    config,
    pkgs,
    lib,
    ...
  }: let
    animations = pkgs.writeText "animations.lua" (import ./_animations.nix);
    keybinds = pkgs.writeText "keybinds.lua" (import ./_keybinds.nix);
    configLua = pkgs.writeText "config.lua" (import ./_config.nix);
    envs = pkgs.writeText "envs.lua" (import ./_envs.nix);
    events = pkgs.writeText "events.lua" (import ./_events.nix {
      inherit self;
      inherit pkgs;
      inherit lib;
    });
    rules = pkgs.writeText "rules.lua" (import ./_rules.nix);
    extra = pkgs.writeText "extra.lua" (import ./_extra.nix);
    monitors = pkgs.writeText "monitors.lua" (import ./_monitors.nix {
      inherit lib;
      monitors = config.preferences.monitors;
    });
  in {
    programs = {
      hyprland = {
        enable = true;
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
    };
    environment.systemPackages = [pkgs.hyprshutdown];
    systemd.user.services = {
      hyprpolkitagent = {
        description = "Hyprland PolicyKit Agent";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
          Restart = "on-failure";
        };
      };
      hyprsunset = {
        description = "Hyprland blue-light filter";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        serviceConfig = {
          ExecStart = "${self.packages.${pkgs.system}.hyprsunset}/bin/hyprsunset";
          Restart = "on-failure";
        };
      };
    };
    hjem.users.${config.preferences.user.name} = {
      files = {
        ".config/hypr/hyprland.lua".text = ''
          require "animations"
          require "keybinds"
          require "config"
          require "envs"
          require "monitors"
          require "events"
          require "rules"
          require "extra"
        '';
        ".config/hypr/animations.lua".source = animations;
        ".config/hypr/keybinds.lua".source = keybinds;
        ".config/hypr/config.lua".source = configLua;
        ".config/hypr/envs.lua".source = envs;
        ".config/hypr/monitors.lua".source = monitors;
        ".config/hypr/events.lua".source = events;
        ".config/hypr/rules.lua".source = rules;
        ".config/hypr/extra.lua".source = extra;
        ".config/xdg-desktop-portal/hyprland-portals.conf".text = ''
          [preferred]
          default=hyprland
          org.freedesktop.impl.portal.ScreenCast=hyprland
          org.freedesktop.impl.portal.Screenshot=hyprland
        '';
      };
    };
  };

  perSystem = {
    self',
    pkgs,
    ...
  }: {
    packages.hyprsunset = let
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

    packages.hyprlandPortal = let
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
  };
}
