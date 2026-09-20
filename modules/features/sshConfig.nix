{...}: {
  flake.nixosModules.sshConfig = {config, ...}: {
    hjem.users.${config.preferences.user.name}.files.".ssh/config".text = ''
      Host 192.168.0.76
        IdentityFile ~/.ssh/id_ed25519_personal
        User artem

      Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519
        IdentitiesOnly yes

      Host github.com.dh
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_dh
        IdentitiesOnly yes
    '';
  };
}
