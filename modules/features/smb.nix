{ self, inputs, ... }: {
  flake.nixosModules.smb = { config, pkgs, ... }:
    let
      homeDir = config.hjem.users.${config.preferences.user.name}.directory;
    in {
      environment = {
        systemPackages = with pkgs; [
          cifs-utils
        ];
      };
      fileSystems."${homeDir}/music/nas" = {
        device = "//192.168.0.225/media/music";
        fsType = "cifs";
        options = [
          "credentials=${homeDir}/.config/smb-nas-credentials"
          "uid=1000"
          "gid=100"
          "vers=3.0"
          "x-systemd.automount"
          "noauto"
          "_netdev"
        ];
      };
    };
}
