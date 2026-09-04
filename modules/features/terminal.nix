{ self, inputs, ... }: {
  perSystem = { self', pkgs, ... }: {
    packages.terminal = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.zsh;
      runtimeInputs = [
        pkgs.htop
        pkgs.zoxide
        pkgs.fzf
      ];
    };
  };
}
