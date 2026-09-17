{ self, inputs, ... }:
{
  flake.nixosModules.pass = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      self.packages.${stdenv.hostPlatform.system}.pass
      pinentry-qt
      zbar
    ];
  };

  perSystem = { pkgs, ... }: {
    packages.pass = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.pass.withExtensions (exts:
        with exts; [
          pass-otp
        ]);
      runtimeInputs = [
        pkgs.passExtensions.pass-otp
      ];
    };
  };
}
