{self, ...}: {
  flake.nixosModules.desktop = {
    config,
    pkgs,
    lib,
    ...
  }: let
    tsVpnEnabled = config.preferences.vpns.ts.enable;
    scriptPackages = self.packages.${pkgs.stdenv.hostPlatform.system};
    customScripts = pkgs.symlinkJoin {
      name = "custom-scripts";
      paths = with scriptPackages; [
        adjust-monitors-by-lid-state
        fetch-split-kb-bats
        forcekillactive
        gamemode
        killactive
        resolution-default
        resolution-for-sharing
        toggle-tailscale
        vpn-disconnect
        dep
      ];
    };
  in {
    imports = [
      self.nixosModules.matugen
      self.nixosModules.kanshi
      self.nixosModules.quickshell
      self.nixosModules.gtk
      self.nixosModules.mpd
    ];

    preferences = {
      quickshell.settings = {
        custom_scripts_path = "${customScripts}/bin";
        disconnect_vpns_path = "${self.packages.${pkgs.stdenv.hostPlatform.system}.vpn-disconnect}/bin/vpn-disconnect.sh";
        vpns = lib.optional tsVpnEnabled {
          toggler_path = "${self.packages.${pkgs.stdenv.hostPlatform.system}.toggle-tailscale}/bin/toggle-tailscale.sh";
          partial_gw_name = "tailscale";
          short_name = "Home Tailscale";
        };
        browsers = [
          {
            name = "Librewolf";
            launch_cmd = "librewolf";
            wk_key = "L";
          }
        ];
      };
    };
    environment = {
      etc = {
        "xdg/user-dirs.defaults".text = ''
          DOWNLOAD=downloads
          DOCUMENTS=documents
          MUSIC=music
          PICTURES=pictures
          VIDEOS=videos
          PROJECTS=projects
        '';
      };
      sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        NIXOS_OZONE_WL = "1";
      };
      systemPackages = with pkgs;
        [
          awww
          libnotify
          bibata-cursors
          grim
          satty
          slurp
          loupe
          vlc
          localsend
          spotify
          qbittorrent
          libreoffice
          discord
          playerctl
          cava
          wl-screenrec
          self.packages.${pkgs.stdenv.hostPlatform.system}.adjust-monitors-by-lid-state
          self.packages.${pkgs.stdenv.hostPlatform.system}.fetch-split-kb-bats
          self.packages.${pkgs.stdenv.hostPlatform.system}.forcekillactive
          self.packages.${pkgs.stdenv.hostPlatform.system}.gamemode
          self.packages.${pkgs.stdenv.hostPlatform.system}.killactive
          self.packages.${pkgs.stdenv.hostPlatform.system}.resolution-default
          self.packages.${pkgs.stdenv.hostPlatform.system}.resolution-for-sharing
          self.packages.${pkgs.stdenv.hostPlatform.system}.vpn-disconnect
        ]
        ++ lib.optional tsVpnEnabled self.packages.${pkgs.stdenv.hostPlatform.system}.toggle-tailscale;
      pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];
    };
    xdg.mime = {
      enable = true;
      defaultApplications = {
        "text/html" = "librewolf.desktop";
        "text/x-patch" = "nvim";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "x-scheme-handler/about" = "librewolf.desktop";
        "x-scheme-handler/unknown" = "librewolf.desktop";
        "image/png" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/jpg" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
      };
    };
    hjem.users.${config.preferences.user.name}.files.".config/mimeapps.list".text = ''
      [Default Applications]
      x-scheme-handler/slack=slack.desktop
      x-scheme-handler/claude-cli=claude-code-url-handler.desktop
      image/png=org.gnome.Loupe.desktop
      image/jpeg=org.gnome.Loupe.desktop
      image/jpg=org.gnome.Loupe.desktop
      image/gif=org.gnome.Loupe.desktop
      image/webp=org.gnome.Loupe.desktop

      [Added Associations]
    '';
    systemd.user.services.xdg-user-dirs-update = {
      description = "Initialize XDG user directories";
      wantedBy = ["graphical-session.target"];
      before = ["graphical-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update";
      };
    };
    fonts.packages = with pkgs; [
      nerd-fonts.meslo-lg
      nerd-fonts.profont
      material-symbols
    ];
    programs = {
      thunar.enable = true;
      firefox = {
        enable = true;
        package = pkgs.librewolf-bin;
        nativeMessagingHosts.packages = [
          pkgs.passff-host
        ];
        preferences = {
          "middlemouse.paste" = false;
          "general.autoScroll" = true;
        };
      };
    };

    preservation = {
      preserveAt."/persistent" = {
        users.${config.preferences.user.name} = {
          directories = [
            ".config/librewolf"
          ];
          files = [
          ];
        };
      };
    };
  };
}
