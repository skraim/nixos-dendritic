{ self, inputs, ... }: {
  flake.nixosModules.workstationNixosConfiguration = { config, pkgs, ... }:
    let
      homeDir = config.hjem.users.${config.preferences.user.name}.directory;
    in {
      imports = [
        self.nixosModules.workstationNixosHardware
        self.nixosModules.general
      ];

      networking.hostName = "ws-nixos";

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
