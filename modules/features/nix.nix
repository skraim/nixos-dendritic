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
        auto-optimise-store = true;
        #         download-buffer-size = 500000000;
        # substituters = [
        #   "https://cache.nixos.org"
        # ];
        #
        # trusted-public-keys = [
        #   "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        # ];
      };
    };
  };
}
