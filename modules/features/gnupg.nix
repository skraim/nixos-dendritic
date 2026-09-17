{ self, inputs, ... }: {
  flake.nixosModules.gnuPG = { config, pkgs, ... }: {
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-qt;
      settings = {
        grab = "";
        default-cache-ttl = 3600;
        max-cache-ttl = 86400;
        allow-preset-passphrase = "";
      };
    };

    hjem.users.${config.preferences.user.name}.files = {
      ".pam-gnupg".text = "8DC4A8D3BB188FC9E265261B2A36C117664BFF56";
    };
  };
}
