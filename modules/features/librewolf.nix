{ inputs, ... }:
let
  librewolfWrapperModule = { config, lib, pkgs, ... }:
    let
      inherit (lib) mkOption types;

      renderPref = name: value: ''
        pref(${builtins.toJSON name}, ${builtins.toJSON value});
      '';
    in {
      options = {
        settings = mkOption {
          type = types.attrsOf (types.oneOf [
            types.bool
            types.int
            types.str
          ]);
          default = {};
          description = "Librewolf preferences to write into the wrapped package.";
        };

        nativeMessagingHosts = mkOption {
          type = types.listOf types.package;
          default = [];
          description = "Native messaging hosts to expose to Librewolf.";
        };
      };

      config = {
        settings = {
          "middlemouse.paste" = false;
          "general.autoScroll" = true;
        };

        nativeMessagingHosts = [ pkgs.passff-host ];

        package = pkgs.librewolf-bin.override {
          inherit (config) nativeMessagingHosts;
          extraPrefs = lib.concatStrings (lib.mapAttrsToList renderPref config.settings);
        };
      };
    };
in {
  perSystem = { pkgs, ... }: {
    packages.librewolf = inputs.wrapper-modules.lib.wrapPackage ({ ... }: {
      inherit pkgs;
      imports = [ librewolfWrapperModule ];
    });
  };
}
