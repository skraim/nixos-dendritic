{ self, inputs, ... }: {
  flake.nixosModules.desktop = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.matugen
      self.nixosModules.kanshi
    ];

    environment = {
      sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        NIXOS_OZONE_WL = "1";
      };
      systemPackages = with pkgs; [
        self.packages.${stdenv.hostPlatform.system}.quickshell
        awww
        libnotify
      ];
      pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
    };
    programs = {
      thunar.enable = true;
      firefox = {
        enable = true;
        package = pkgs.librewolf-bin;
        nativeMessagingHosts.packages = [
          pkgs.passff-host
        ];
        wrapperConfig = {
          "middlemouse.paste" = false;
          "general.autoScroll" = true;
        };
      };
    };
  };
}
