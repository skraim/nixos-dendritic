{ self, inputs, ... }: {
  perSystem = { self', pkgs, lib, ... }: {
    packages.terminal =
      (inputs.wrappers.wrapperModules.kitty.apply {
        inherit pkgs;
        imports = [self.wrappersModules.kitty];
        shell = lib.getExe self'.packages.sh;
      }).wrapper;

    packages.sh = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.zsh;
      runtimeInputs = with pkgs; [
        fzf
        ripgrep
        fd
        # neovim
        direnv
        jq
        tmuxp
        tldr
        self'.packages.lazygit
        self'.packages.fastfetch
        self'.packages.btop
        self'.packages.nh
        self'.packages.yazi
        self'.packages.less
        self'.packages.bat
        self'.packages.neovim
      ];
    };
  };
}
