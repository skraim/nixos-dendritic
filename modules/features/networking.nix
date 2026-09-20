{...}: {
  flake.nixosModules.networking = {
    config,
    lib,
    pkgs,
    ...
  }: let
    tsVpnEnabled = config.preferences.vpns.ts.enable;
  in {
    networking = {
      firewall.checkReversePath = "loose";
      networkmanager.enable = true;
    };
    services.tailscale.enable = tsVpnEnabled;
    preservation = lib.mkIf tsVpnEnabled {
      preserveAt."/persistent" = {
        directories = [
          "/var/lib/tailscale"
        ];
      };
    };
  };
}
