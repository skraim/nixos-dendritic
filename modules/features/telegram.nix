{ ... }: {
  flake.nixosModules.telegram = { pkgs, config, ... }: {
    environment.systemPackages = [
      pkgs.telegram-desktop
    ];

    preservation = {
      preserveAt."/persistent" = {
        users.${config.preferences.user.name} = {
          directories = [
            ".local/share/TelegramDesktop"
          ];
        };
      };
    };
  };
}
