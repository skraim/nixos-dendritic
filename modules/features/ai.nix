{ ... }: {
  flake.nixosModules.ai = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      claude-code
      codex
      sox
    ];
  };
}
