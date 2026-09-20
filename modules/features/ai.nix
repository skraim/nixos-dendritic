{...}: {
  flake.nixosModules.ai = {
    config,
    pkgs,
    ...
  }: {
    environment.systemPackages = with pkgs; [
      claude-code
      codex
      sox
    ];

    preservation = {
      preserveAt."/persistent" = {
        users.${config.preferences.user.name} = {
          directories = [
            ".codex"
            ".claude"
          ];
        };
      };
    };
  };
}
