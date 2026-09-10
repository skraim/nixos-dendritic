{ self, inputs, ... }: {
  flake.nixosModules.development = { config, pkgs, ... }: {
    programs.npm = {
      enable = true;
      package = pkgs.nodejs_22;
      npmrc = ''
        min-release-age=7
      '';
    };

    environment.systemPackages = with pkgs; [
      expect
    ];
    
    # todo: java
  };
}
