{ ... }: {
  perSystem = { pkgs, ... }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.dbus-next ps.pycryptodome ]);
      ironkeyUnlockerSrc = pkgs.fetchFromGitHub {
        owner = "wltechblog";
        repo = "ironkey-unlocker";
        rev = "b7ac4275ad29cdcc6a5a476868f9c9293133997a";
        hash = "sha256-vLYM/bcG5dh2dat79xbVai4X+QKDVRQoCalYAa6QA2c=";
      };
      shellScript = name: pkgs.writeShellScriptBin name
        (builtins.readFile (./scripts + "/${name}"));
      pythonScript = name: pkgs.writeScriptBin name
        (builtins.replaceStrings [ "#!/usr/bin/env python3" ] [ "#!${python}/bin/python" ]
          (builtins.readFile (./scripts + "/${name}")));
    in {
      packages = {
        adjust-monitors-by-lid-state = shellScript "adjust-monitors-by-lid-state.sh";
        dep = shellScript "dep";
        forcekillactive = shellScript "forcekillactive.sh";
        gamemode = shellScript "gamemode.sh";
        killactive = shellScript "killactive.sh";
        resolution-default = shellScript "resolution-default.sh";
        resolution-for-sharing = shellScript "resolution-for-sharing.sh";
        toggle-tailscale = shellScript "toggle-tailscale.sh";
        vpn-disconnect = shellScript "vpn-disconnect.sh";
        xdg-open = shellScript "xdg-open";

        fetch-split-kb-bats = pythonScript "fetch-split-kb-bats.sh";
        ironkey-unlock = pkgs.stdenvNoCC.mkDerivation {
          pname = "ironkey-unlocker";
          version = "unstable-2026-06-01";
          src = ironkeyUnlockerSrc;

          installPhase = ''
            install -Dm755 ironkey_unlock.py $out/bin/ironkey-unlock
            substituteInPlace $out/bin/ironkey-unlock \
              --replace-fail '#!/usr/bin/env python3' '#!${python}/bin/python'
          '';
        };
      };
    };
}
