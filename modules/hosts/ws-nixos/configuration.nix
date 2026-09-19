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
        self.nixosModules.chromium
        self.nixosModules.ai
        self.nixosModules.sshConfig
        self.nixosModules.handlr
        self.diskoConfigurations.workstationNixos
        self.nixosModules.preservation
      ];

      networking.hostName = "ws-nixos";
      preferences = {
        vpns.ts.enable = true;
        quickshell.settings = {
          browsers = [
            {
              name = "Chromium";
              launch_cmd = "chromium";
              wk_key = "C";
            }
          ];
        };
        monitors = [
          {
            name = "eDP-1";
            scale = "1.2";
          }
          {
            name = "desc:Xiaomi Corporation Mi Monitor";
            width = 3440;
            height = 1440;
            refreshRate = 100;
            x = 1600;
            y = -50;
          }
        ];
      };
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
      services = {
        upower.enable = true;
        power-profiles-daemon.enable = true;
        xserver = {
          videoDrivers = [ "modesetting" ];
        };
      };
      environment = {
        sessionVariables = {
          LIBVA_DRIVER_NAME = "iHD";
        };
        systemPackages = with pkgs; [
          intel-compute-runtime
          brightnessctl
          slack
          self.packages.${pkgs.stdenv.hostPlatform.system}.ironkey-unlock
        ];
      };
      xdg.mime.defaultApplications = {
        "application/pdf" = "chromium-browser.desktop";
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
