{ self, ... }: {
  flake.nixosModules.development = { config, pkgs, ... }: {
    programs = { 
      java.enable = true;
      npm = {
        enable = true;
        package = pkgs.nodejs_22;
        npmrc = ''
        min-release-age=7
        '';
      };
    };
    environment.systemPackages = with pkgs; [
      maven
      self.packages.${pkgs.stdenv.hostPlatform.system}.dep
    ];
  };
}
