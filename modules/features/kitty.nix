{ self, inputs, ... }: {
  flake.wrappersModules.kitty = { config, lib, ... }: {
    # let
    #   homeDir = config.hjem.users.${config.preferences.user.name}.directory;
    # in {
      options.shell = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      config = {
        args = lib.mkAfter (lib.optionals (config.shell != "") [config.shell]);
        settings = {
          font_size = 12;
          font_family = "MesloLGL Nerd Font";
          scrollback_lines = 5000;
          window_margin_width = "5 10";
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          auto_reload_config = -1;
          enable_audio_bell = "no";
          shell_integration = "enabled";
          cursor_trail = 1;
          cursor_text_color = "#31748f";
          map = [
            "kitty_mod+a scroll_line_up"
            "kitty_mod+h scroll_line_down"
            "kitty_mod+comma scroll_line_up"
            "kitty_mod+p scroll_line_down"
          ];
        };
        extraSettings = ''
          include $HOME/.config/kitty/current-theme.conf
          include $HOME/.config/kitty/background-color.conf
        '';
      };
    };
}
