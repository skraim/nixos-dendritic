{ self, inputs, ... }: {
  flake.nixosModules.mpd = { config, pkgs, ... }:
    let
      user = config.preferences.user.name;
      homeDir = config.hjem.users.${user}.directory;
      dataDir = "${homeDir}/.local/state/mpd";
      mpdConfig = pkgs.writeText "mpd.conf" ''
        music_directory "${homeDir}/music"
        playlist_directory "${dataDir}/playlists"
        db_file "${dataDir}/tag_cache"
        state_file "${dataDir}/state"
        sticker_file "${dataDir}/sticker.sql"
        bind_to_address "127.0.0.1"
        port "6600"
        auto_update "yes"

        audio_output {
          type "fifo"
          name "my_fifo"
          path "/tmp/mpd.fifo"
          format "44100:16:2"
        }

        audio_output {
          type "pipewire"
          name "PipeWire output"
        }
      '';
    in {
      environment.systemPackages = with pkgs; [
        self.packages.${pkgs.stdenv.hostPlatform.system}.rmpc
      ];
      hjem.users.${user}.files.".config/mpDris2/mpDris2.conf".text = ''
        [Connection]
        host = 127.0.0.1
        port = 6600
        music_dir = ${homeDir}/music

        [Bling]
        notify = False
        mmkeys = False
      '';

      systemd.user.services = {
        mpd = {
          description = "Music Player Daemon";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          wants = [ "pipewire.service" ];
          after = [ "pipewire.service" "wireplumber.service" ];
          serviceConfig = {
            Type = "notify";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${dataDir}/playlists";
            ExecStart = "${pkgs.mpd}/bin/mpd --no-daemon ${mpdConfig}";
            Restart = "on-failure";
          };
        };

        mpdris2 = {
          description = "MPRIS 2 support for MPD";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          requires = [ "mpd.service" ];
          after = [ "mpd.service" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.mpdris2}/bin/mpDris2";
            Restart = "on-failure";
            RestartSec = "5s";
            BusName = "org.mpris.MediaPlayer2.mpd";
          };
        };
    };
  };

  perSystem = { pkgs, ... }: {
    packages.rmpc =
      let
        songNotify = pkgs.writeShellScript "rmpc-song-notify" (builtins.readFile ./song-notify.sh);
        rmpcConfig = pkgs.writeText "rmpc-config.ron" (
          builtins.replaceStrings
            [ "./song-notify.sh" ]
            [ (toString songNotify) ]
            (builtins.readFile ./config.ron)
        );
      in
        inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.rmpc;
          flags."--config" = rmpcConfig;
          runtimeInputs = [ pkgs.libnotify pkgs.rmpc ];
        };
  };
}
