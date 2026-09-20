{ self, ... }: {
  flake.nixosModules.quickshell = { config, lib, pkgs, ... }:
    let
      cfg = config.preferences.quickshell;
      settingsFile = pkgs.writeText "quickshell-settings.json" (builtins.toJSON cfg.settings);
      relativePath = path: lib.removePrefix "${toString ./.}/" (toString path);
      configFiles = builtins.listToAttrs (map (path: {
        name = ".config/quickshell/${relativePath path}";
        value.source = path;
      }) (lib.filter (path: let relative = relativePath path; in relative != "quickshell.nix" && relative != "settings.json") (lib.filesystem.listFilesRecursive ./.)));
    in {
      options.preferences.quickshell.settings = lib.mkOption {
        description = "Settings written to Quickshell's settings.json.";
        type = lib.types.submodule {
          options = {
            language = lib.mkOption { type = lib.types.enum [ "en" "ua" ]; default = "en"; };
            custom_scripts_path = lib.mkOption { type = lib.types.str; default = "~/scripts"; };
            cache_path = lib.mkOption { type = lib.types.str; default = "~/.cache/quickshell"; };
            wallpapers_path = lib.mkOption { type = lib.types.str; default = "~/pictures/wallpapers"; };
            active_wallpaper_cmd = lib.mkOption { type = lib.types.str; default = "awww query -j | jq -r 'first(.[].[]?.displaying.image // empty)'"; };
            wallpaper_cmd_dark = lib.mkOption { type = lib.types.str; default = "matugen image $@ --source-color-index $((RANDOM % $(matugen image $@ --show-source-colors | wc -l)))"; };
            wallpaper_cmd_light = lib.mkOption { type = lib.types.str; default = "matugen image $@ --source-color-index $((RANDOM % $(matugen image $@ --show-source-colors | wc -l))) -m light"; };
            vpns = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  toggler_path = lib.mkOption { type = lib.types.str; };
                  partial_gw_name = lib.mkOption { type = lib.types.str; };
                  short_name = lib.mkOption { type = lib.types.str; };
                };
              });
              default = [ ];
            };
            disconnect_vpns_path = lib.mkOption { type = lib.types.str; default = "$HOME/scripts/vpn-disconnect.sh"; };
            calendar_first_day_of_week = lib.mkOption { type = lib.types.ints.between 0 6; default = 1; };
            screens = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ "Chimei Innolux Corporation 0x1435" "Xiaomi Corporation Mi Monitor" ]; };
            main_screen = lib.mkOption { type = lib.types.str; default = "Xiaomi Corporation Mi Monitor"; };
            max_notifications = lib.mkOption { type = lib.types.attrsOf lib.types.int; default = { "Chimei Innolux Corporation 0x1435" = 2; "Xiaomi Corporation Mi Monitor" = 3; }; };
            power_menu_monitor_columns = lib.mkOption { type = lib.types.attrsOf lib.types.int; default = { "Chimei Innolux Corporation 0x1435" = 3; "Xiaomi Corporation Mi Monitor" = 6; }; };
            notification_center_ignore_apps = lib.mkOption { type = lib.types.listOf lib.types.str; default = [ "satty" "SNX" "VPN" "zsh" "Shell" ]; };
            distro_icon = lib.mkOption { type = lib.types.str; default = "assets/nixos.svg"; };
            power_menu_cmds = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  lock = lib.mkOption { type = lib.types.str; default = "hyprlock"; };
                  monitorOff = lib.mkOption { type = lib.types.str; default = "sleep 0.5 && hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'"; };
                  suspend = lib.mkOption { type = lib.types.str; default = "hyprshutdown -t 'Suspending...' --post-cmd systemctl suspend"; };
                  logout = lib.mkOption { type = lib.types.str; default = "hyprshutdown -t 'Logging out...'"; };
                  reboot = lib.mkOption { type = lib.types.str; default = "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"; };
                  shutdown = lib.mkOption { type = lib.types.str; default = "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"; };
                };
              };
              default = {};
            };
            app_icons = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = {
                chromium-browser = "assets/chromium.svg";
                nm-connection-editor = "assets/NetworkManager.svg";
                preferences-system-network = "assets/NetworkManager.svg";
                drive-removable-media = "assets/drive-removable-media.png";
                orca-slicer = "assets/orca-slicer.png";
              };
            };
            browsers = lib.mkOption {
              type = lib.types.listOf (lib.types.submodule {
                options = {
                  name = lib.mkOption { type = lib.types.str; };
                  launch_cmd = lib.mkOption { type = lib.types.str; };
                  wk_key = lib.mkOption { type = lib.types.str; };
                };
              });
              default = [ ];
            };
          };
        };
        default = {};
      };

      config = {

        environment = {
          # variables = {
          #   QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
          # };
          systemPackages = with pkgs; [
            quickshell
            # coreutils
            # findutils
            # gawk
            # gnugrep
            # gnused
            # iproute2
            # networkmanager
            jq
                  qt6.qt5compat

            qt6.qtquick3d
            qt6.qtwayland
            qt6.qtdeclarative
            qt6.qtsvg
            kdePackages.qtmultimedia
            material-symbols
            # self.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
            # self.packages.${pkgs.stdenv.hostPlatform.system}.matugen
            # awww
          ];
        };

        hjem.users.${config.preferences.user.name}.files = configFiles // {
          ".config/quickshell/settings.json".source = settingsFile;
        };
      };
    };
}
