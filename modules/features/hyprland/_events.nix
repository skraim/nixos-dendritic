{
  self,
  pkgs,
  lib,
}:
#lua
''
  hl.on("hyprland.start", (function ()
    hl.exec_cmd("dbus-update-activation-environment --all --systemd")
    hl.exec_cmd("${lib.getExe pkgs.hyprland-per-window-layout}")
    hl.exec_cmd("${lib.getExe pkgs.udiskie} & awww-daemon")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("systemctl --user start hyprsunset")
    hl.exec_cmd("systemctl --user start hypridle")
    hl.exec_cmd("systemctl --user start kanshi")
    hl.exec_cmd("quickshell")
    hl.exec_cmd("sleep 1; ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.matugen} image \"$(find ~/pictures/wallpapers -type f,l | shuf -n 1)\" --source-color-index 0")
    hl.exec_cmd("${lib.getExe pkgs.telegram-desktop}")
    hl.exec_cmd("${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type text --watch cliphist store")
    hl.exec_cmd("${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch cliphist store")
    hl.exec_cmd("${lib.getExe pkgs.wl-clip-persist} --clipboard regular")
    hl.exec_cmd("rm \"$HOME/.cache/cliphist/db\"")
    hl.exec_cmd("${lib.getExe pkgs.brightnessctl} -s set 50%")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
  end
  ))
  hl.on("window.active", (function (window, reason)
    if reason == 1 then
      hl.timer(function()
        if window.address == hl.get_active_window().address then
          hl.dispatch(hl.dsp.layout("fit_into_view"))
        end
      end, { timeout = 1000, type = "oneshot" })
    end
  end
  ))
''
