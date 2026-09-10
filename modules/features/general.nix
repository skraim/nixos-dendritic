{ self, inputs, ... }: {
  flake.nixosModules.general = { config, pkgs, ... }:
    let
      user = config.preferences.user.name;
    in {
      imports = [
        self.nixosModules.hjem
        self.nixosModules.base
        self.nixosModules.xkb
        self.nixosModules.i18n
        self.nixosModules.networking
        self.nixosModules.nix
        self.nixosModules.ly
        self.nixosModules.pipewire
        self.nixosModules.wlClipboard
      ];

      fonts.packages = [
        pkgs.google-fonts
      ];
      users.users.${user} = {
        shell = self.packages.${pkgs.stdenv.hostPlatform.system}.sh;
        isNormalUser = true;
        description = "${user}";
        extraGroups = [ "networkmanager" "wheel" "dialout" "ydotool" ];
        initialPassword = "12345";
      };

      hjem.users.${user} = {
        # credits: u/NGB_UF @ reddit.com
        files."Pictures/wallpapers/nixos-wall.png".source = ./wallpaper/nixos-wall.png;
      };

      qt.enable = true;
      environment.systemPackages = with pkgs; [
        self.packages.${pkgs.stdenv.hostPlatform.system}.terminal
        (python313.withPackages (ps: with ps; [ dbus-next pycryptodome ]))
        udiskie
        glib
        lsof
        unzip
        gcc_multi
        git # todo: make wrapper
        imagemagick
        cargo
      ];

      security = {
        pam.services.login = {
          gnupg = {
            enable = true;
            storeOnly = true;
          };
          enableGnomeKeyring = true;
        };

        rtkit.enable = true;
        polkit.enable = true;
        sudo.extraConfig = ''
          Defaults pwfeedback
          Defaults timestamp_timeout = 300
        '';
      };

      programs = {
        ydotool.enable = true;
        nix-ld = {
          enable = true;
          # libraries = with pkgs; [
          #   nodejs_22
          #   brotli
          #   unixodbc
          #   zstd
          #   glib
          #   stdenv.cc.cc
          # ];
        };
      };

      services = {
        udisks2.enable = true;
        gnome.gnome-keyring.enable = true;
        libinput.enable = true;
      };
    };
}
