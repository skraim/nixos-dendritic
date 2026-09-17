{ self, inputs, lib, ... }: {
  flake.nixosModules.nix = {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) [
        "spotify"
        "discord"
        "discord-unwrapped"
        "slack"
        "steam"
        "steam-unwrapped"
        "claude-code"
      ];
    nix = {
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 14d";
      };

      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        auto-optimise-store = true;
      };
    };
  };
}
