{ self, inputs, ... }: {
  perSystem = { self', pkgs, ... }: {
    packages.terminal = inputs.wrapper-modules.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.zsh;
      runtimePkgs = [
        pkgs.htop
        pkgs.zoxide
        pkgs.fzf
        pkgs.lazygit
      ];
    };
  };
}
