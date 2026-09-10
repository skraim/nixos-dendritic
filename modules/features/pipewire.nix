{ self, inputs, ... }: {
  flake.nixosModules.pipewire = { pkgs, ... }: {
    services = {
      pipewire = {
        enable = true;
        pulse.enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        wireplumber = {
          enable = true;
          configPackages = [
            (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-mitigate-annoying-profile-switch.conf" ''
            wireplumber.settings = {
              bluetooth.autoswitch-to-headset-profile = false
            }

            monitor.bluez.properties = {
              bluez5.roles = [ a2dp_sink a2dp_source ]
            }
            '')
          ];
        };
        extraConfig.pipewire = {
          "10-block-agc" = {
            "pulse.rules" = [
              {
                matches = [
                  { "application.process.binary" = "~.*"; }
                ];
                actions = {
                  quirks = [ "block-source-volume" ];
                };
              }
            ];
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      pavucontrol
    ];
  };
}
