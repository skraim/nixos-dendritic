{ self, inputs, ... }: {
  perSystem = { pkgs, ... }:
    let
      lesskey = pkgs.writeText "lesskey" ''
        h forw-line
        a back-line
      '';
    in {
      packages.less = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.less;
        flags."--lesskey-src" = lesskey;
      };
    };
}
