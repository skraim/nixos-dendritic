{ self, inputs, ... }: {
  flake.nixosModules.workstationNixosConfiguration = { config, pkgs, ... }:
    {
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

      system.stateVersion = "25.05";
    };
}
