{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.kitty = inputs.wrapper-modules.wrappers.kitty.wrap {
      inherit pkgs;

      font = {
        name = "MesloLGL Nerd Font";
        size = 12;
      };
      keybindings = {
        "kitty_mod+a" = "scroll_line_up";
        "kitty_mod+h" = "scroll_line_down";
        "kitty_mod+comma" = "scroll_line_up";
        "kitty_mod+p" = "scroll_line_down";
      };
      settings = {
        cursor_trail = 1;
        scrollback_lines = 5000;
        window_margin_width = "5 10";
        enable_audio_bell = "no";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";
        auto_reload_config = -1;
      };
      extraConfig = ''
        include ~/.config/kitty/current-theme.conf
        include ~/.config/kitty/background-color.conf
        cursor                   #31748f
      '';
    };
  };
}
