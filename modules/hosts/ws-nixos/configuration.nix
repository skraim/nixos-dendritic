{ self, inputs, ... }: {
  flake.nixosModules.workstationNixosConfiguration = { config, pkgs, ... }:
    let
      homeDir = config.hjem.users.${config.preferences.user.name}.directory;
    in {
      imports = [
        self.nixosModules.workstationNixosHardware
        self.nixosModules.general
        self.nixosModules.hyprland
        self.nixosModules.desktop
        self.nixosModules.openlogi
        self.nixosModules.virtualisation
        self.nixosModules.telegram
        self.nixosModules.pass
        self.nixosModules.gaming
        self.nixosModules.development
        self.nixosModules.bluetooth
        self.nixosModules.cadAnd3dPrinting
        self.nixosModules.smb
      ];

      networking.hostName = "ws-nixos";
      preferences.vpns.ts.enable = true;

      boot = {
        loader =
          {
            timeout = 2;
            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
          };

        kernelParams = [ "i915.enable_guc=3" ];
        kernelPackages = pkgs.linuxPackages_latest;
      };

      programs = {
        nix-index-database.comma.enable = true;
      };

      hardware = {
        enableRedistributableFirmware = true;
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            intel-media-driver
            vpl-gpu-rt
            intel-compute-runtime
          ];
        };
      };
  #   bluetooth = {
  #     enable = true;
  #     powerOnBoot = true;
  #     settings = {
  #       General = {
  #         Experimental = true;
  #         FastConnectable = true;
  #       };
  #       Policy = {
  #         AutoEnable = true;
  #         ReconnectAttempts = 0;
  #       };
  #     };
  #   };
  # };

        services = {
  #   pcscd.enable = true;
  #   udisks2.enable = true;
    upower.enable = true;
  #   gnome.gnome-keyring.enable = true;
  #   xl2tpd.enable = true;
  #   libinput.enable = true;
    power-profiles-daemon.enable = true;
  #   tailscale.enable = true;
  #   strongswan = {
  #     enable = true;
  #     secrets = [
  #       "ipsec.d/ipsec.nm-l2tp.secrets"
  #     ];
  #   };
    xserver = {
      videoDrivers = [ "modesetting" ];
    };
  };
  environment = {
  #   etc = {
  #     "strongswan.conf".text = ''
  #       charon {
  #         filelog {
  #           charon {
  #             path = /var/log/charon.log
  #             default = 2
  #           }
  #         }
  #       }
  #     '';
  #
  #     "ipsec.secrets".text = ''
  #     '';
  #   };
  #
  #   variables = {
  #     QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
  #   };
  #
    sessionVariables = {
  #     QT_QPA_PLATFORM = "wayland;xcb";
  #     QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      LIBVA_DRIVER_NAME = "iHD";
      # NIXOS_OZONE_WL = "1";
    };
  #
  #   shells = [ pkgs.zsh ];
    systemPackages = with pkgs; [
  #     cifs-utils
  #     (python313.withPackages (ps: with ps; [ dbus-next pycryptodome ]))
      intel-compute-runtime
      brightnessctl
  #     expect
  #     pinentry-qt
  #     pavucontrol
  #     nettools
  #     glib
  #     lsof
  #     unzip
  #     gcc_multi
  #     libxml2
  #     wl-clip-persist
  #     git
  #     udiskie
  #     imagemagick
  #     cargo
  #     nh
  #     libnotify
  #     # networkmanagerapplet
  #     sddm-astronaut
  #     cachix
  #     kitty
  #     spnavcfg
  #     ripgrep
  #     fd
  #     qtcreator
  #     # inputs.matugen.packages.${system}.default
  #     virt-viewer
    ];
  #   # pathsToLink = [ "/share/applications" "/share/xdg-desktop-portal" ];
  };



      sops = {
        age.sshKeyPaths = [ "${homeDir}/.ssh/id_ed25519_personal" ];
        defaultSopsFile = "${self.outPath}/secrets.yaml";
        secrets = {
          personal_email = {};
          git_name_lw = {};
          git_email_lw = {};
          git_name_dl = {};
          git_email_dl = {};
          git_name_dh = {};
          git_email_dh = {};
          git_name_sc = {};
          git_email_sc = {};
          anthropic_api_key = {};
          link_regex_sc = {};
          link_regex_lw = {};
          link_regex_dl1 = {};
          link_regex_dl2 = {};
          proj_dir_dlfe = {};
          proj_runcmd_dlfe = {};
          proj_dir_dlaem = {};
          proj_dir_sc = {};
          proj_dir_lw = {};
          smb_nas_credentials = {
            path = "${homeDir}/.config/smb-nas-credentials";
            mode = "0400";
          };
        };
      };

      system.stateVersion = "25.05";
    };
}
