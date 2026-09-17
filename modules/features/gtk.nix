{ self, inputs, ... }: {
  flake.nixosModules.gtk = { pkgs, lib, ... }:
    let
      theme-package = pkgs.catppuccin-gtk;
      icon-theme-package = pkgs.rose-pine-icon-theme;
      theme-name = "catppuccin-frappe-blue-standard";
      icon-theme-name = "rose-pine";
      gtksettings = ''
        [Settings]
        gtk-icon-theme-name = ${icon-theme-name}
        gtk-theme-name = ${theme-name}
      '';
    in {
      environment = {
        etc = {
          "xdg/gtk-3.0/settings.ini".text = gtksettings;
          "xdg/gtk-4.0/settings.ini".text = gtksettings;
        };
      };

      environment.variables = {
        GTK_THEME = theme-name;
      };

      programs = {
        dconf = {
          enable = lib.mkDefault true;
          profiles = {
            user = {
              databases = [
                {
                  lockAll = false;
                  settings = {
                    "org/gnome/desktop/interface" = {
                      gtk-theme = theme-name;
                      icon-theme = icon-theme-name;
                      color-scheme = "prefer-dark";
                    };
                  };
                }
              ];
            };
          };
        };
      };

      environment.systemPackages = [
        theme-package
        icon-theme-package
      ];
    };
}
