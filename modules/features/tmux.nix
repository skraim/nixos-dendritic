{ self, inputs, ... }: {
  flake.nixosModules.tmux = { config, pkgs, ... }: {
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.tmux
    ];

    hjem.users.${config.preferences.user.name}.files = {
      ".tmuxp/nix.yaml".text = ''
        session_name: nix
        start_directory: ~/nixos/
        windows:
          - window_name: dev
            focus: true
            panes:
            - shell_command:
              - cmd: nvim .
          - window_name: git
            panes:
              - shell_command: lazygit
          - window_name: shell
            panes:
              - shell_command:
          - window_name: todo
            panes:
              - shell_command:
                - cmd: nvim ~/documents/todos/setup.todo.md
      '';
    };
  };

  perSystem = { self', lib, pkgs, ... }: {
    packages.tmux = inputs.wrapper-modules.wrappers.tmux.wrap {
      inherit pkgs;

      terminal = "xterm-256color";
      baseIndex = 1;
      paneBaseIndex = 1;
      shell = lib.getExe self'.packages.sh;
      statusKeys = "emacs";
      modeKeys = "emacs";
      mouse = true;
      aggressiveResize = false;
      clock24 = false;
      escapeTime = 0;
      historyLimit = 5000;
      terminalOverrides = ",xterm-256color:Tc";
      updateEnvironment = [ "TERM_PROGRAM" ];
      visualActivity = false;

      configAfter = ''
        set -g focus-events on
        set -g allow-passthrough all
        set -g status-position top
        set -g status-left "#[fg=blue,bg=default] #[fg=black,bg=blue] #S #[fg=blue,bg=default]  "
        set -g status-right "#[fg=green]#{server_sessions} session(s) #[fg=cyan,bold,bg=default]%a %Y-%m-%d %H:%M"
        set -g status-justify left
        set -g status-left-length 200
        set -g status-right-length 200
        set -g status-style 'bg=default'
        set -g window-status-current-format '#[fg=magenta,bg=default]#[fg=black,bg=magenta]#[bold]#I#[nobold]: #W#[fg=magenta,bg=default]'
        set -g window-status-format '#[fg=gray,bg=default]#[bold]#I#[nobold]: #W'
        bind y select-pane -L
        bind h select-pane -D
        bind a select-pane -U
        bind e select-pane -R
      '';
    };
  };
}
