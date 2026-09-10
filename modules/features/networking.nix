{ self, inputs, ... }: {
  flake.nixosModules.networking = { config, lib, pkgs, ... }:
    let
      snxVpnEnabled = config.preferences.vpns.snx.enable;
      scVpnEnabled = config.preferences.vpns.sc.enable;
      tsVpnEnabled = config.preferences.vpns.ts.enable;
    in {
      networking = {
        firewall.checkReversePath = "loose";
        networkmanager = {
          enable = true;
          plugins = lib.optionals scVpnEnabled (with pkgs; [
            networkmanager-fortisslvpn
            networkmanager-l2tp
            networkmanager-openvpn
            networkmanager-strongswan
          ]);
        };
      };

      services = {
        strongswan = {
          enable = scVpnEnabled;
          secrets = lib.optionals scVpnEnabled [
            "ipsec.d/ipsec.nm-l2tp.secrets"
          ];
        };
        tailscale.enable = tsVpnEnabled;
        xl2tpd.enable = scVpnEnabled;
      };

      environment = lib.mkIf scVpnEnabled {
        etc = {
          "strongswan.conf".text = ''
        charon {
          filelog {
            charon {
              path = /var/log/charon.log
              default = 2
            }
          }
        }
          '';

          "ipsec.secrets".text = ''
          '';
        };
      };

      systemd.services = lib.mkIf snxVpnEnabled {
        snx-rs = {
          description = "SNX-RS Service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.snx-rs}/bin/snx-rs -m command -l info";
            Restart = "on-failure";
            RestartPreventExitStatus = [ 1 2 255 ];
          };
          path = [pkgs.iproute2 pkgs.kmod];
        };
      };
    };
}
