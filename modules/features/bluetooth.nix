{ self, inputs, ... }: {
  flake.nixosModules.bluetooth = { config, pkgs, ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          FastConnectable = true;
        };
        Policy = {
          AutoEnable = true;
          ReconnectAttempts = 0;
        };
      };
    };
  };
}
