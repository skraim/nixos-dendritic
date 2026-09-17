{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.git = {
    config,
    pkgs,
    ...
  }: let
    user = config.preferences.user.name;
  in {
    sops.templates.gitconfig-personal = {
      owner = user;
      content = ''
        [user]
          name = Artem
          email = ${config.sops.placeholder.personal_email}
      '';
    };

    sops.templates.gitconfig-dh = {
      owner = user;
      content = ''
        [user]
          name = ${config.sops.placeholder.git_name_dh}
          email = ${config.sops.placeholder.git_email_dh}
      '';
    };

    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.git
    ];
  };

  perSystem = {pkgs, ...}: {
    packages.git = inputs.wrapper-modules.wrappers.git.wrap {
      inherit pkgs;
      settings = {
        include.path = "/run/secrets/rendered/gitconfig-personal";
        includeIf."gitdir:~/Projects/dh/".path = "/run/secrets/rendered/gitconfig-dh";
      };
    };
  };
}
