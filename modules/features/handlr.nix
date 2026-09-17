{ self, ... }: {
  flake.nixosModules.handlr = { config, pkgs, ... }: {
    environment.systemPackages = [
      pkgs.handlr-regex
      self.packages.${pkgs.stdenv.hostPlatform.system}.xdg-open
    ];

    hjem.users.${config.preferences.user.name}.files.".config/handlr/handlr.toml".text = ''
      [[handlers]]
      exec = "chromium %u"
      regexes = [
        '(https://)?(.*\.)?atlassian\.net/*.',
        '(https://)?(.*\.)?azure.*\.(com|net)/*.',
        '(https://)?(.*\.)?slack\.com/*.',
        '(https://)?(.*\.)?phrase\.com/*.',
      ]
    '';
  };
}
