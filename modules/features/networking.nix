{ self, inputs, ... }: {
  flake.nixosModules.networking = { pkgs, ... }: {
    networking = {
      firewall.checkReversePath = "loose";
      networkmanager = {
        enable = true;
        plugins = with pkgs; [
          networkmanager-fortisslvpn
          networkmanager-l2tp
          networkmanager-openvpn
          networkmanager-strongswan
        ];
      };
    };
  };
}
