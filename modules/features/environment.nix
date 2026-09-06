{ self, inputs, ... }: {
  perSystem = { self', pkgs, ... }: {
    packages.terminal = inputs.wrapper-modules.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.kitty;
      runtimePkgs = [
        self'.packages.zsh
      ];
    };

    packages.sh = inputs.wrapper-modules.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.zsh;
      runtimePkgs = [
        pkgs.fzf
        pkgs.lazygit
        self'.packages.fastfetch
      ];
    };
  };
}
