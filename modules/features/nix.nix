{ self, inputs, ... }: {
  flake.nixosModules.nix = {
    nixpkgs.config.allowUnfree = true;
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        # auto-optimise-store = true;
        # download-buffer-size = 500000000;
      };
    };
  };
}
