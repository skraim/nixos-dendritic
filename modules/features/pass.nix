{ self, inputs, ... }:
{
  flake.nixosModules.pass = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      self.packages.${stdenv.hostPlatform.system}.pass
      pinentry-qt
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
      # maybe remove the bottom
      # env = {
      #   PASSWORD_STORE_DIR = "${config.hjem.users.${config.preferences.user.name}.directory}/.password-store";
      # };
    };
  };
}
