{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.zsh = inputs.wrapper-modules.wrappers.zsh.wrap {
      inherit pkgs;

      skipGlobalRC = true;
      zshAliases = {
        ls = "ls -lhA --color=auto --group-directories-first";
        lg = "lazygit";
        ":q" = "exit";
        txl = "tmuxp load";
        txk = "tmux kill-session";
        txa = "tmux a";
        txls = "tmux ls";
        tx = "tmux";
        gd = "cd ~/Downloads";
        ge = "cd /run/media/$USER";
        gp = "cd ~/Pictures";
        v = "nvim";
        cam = "guvcview";
        fd = "fd --hidden";
        rg = "rg --hidden";
        cat = "bat";
        trash = "gio trash";
        ff = "fastfetch";
        nrs = "sudo nixos-rebuild switch --flake ~/nixos --impure";
        ns = "nix-shell";
      };
      zshrc.content = ''
        autoload -U compinit
        zstyle ':completion:*' menu select
        zmodload zsh/complist
        compinit
        _comp_options+=(globdots)

        bindkey -e
        bindkey '^e' edit-command-line
        bindkey '^H' backward-kill-word
        bindkey '^[[3;5~' kill-word
        bindkey '^[[3~' delete-char
        bindkey '^[[1;5D' backward-word
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5A' beginning-of-line
        bindkey '^[[1;5B' end-of-line
        zstyle :zle:edit-command-line editor nvim
        autoload -Uz edit-command-line
        zle -N edit-command-line

        export FZF_DEFAULT_OPTS="--style minimal --color 16 --layout reverse --height 40% --preview='bat -p --color=always {}'"
        export MANPAGER="/bin/sh -c 'col -bx | bat -l man -p'"
        export MANROFFOPT="-c"
        export TERM="xterm-256color"
        export KITTY_CONFIG_DIRECTORY="$HOME/.config/kitty/"
        typeset -a AUTO_NOTIFY_IGNORE=(docker man sleep yazi yy nvim lazygit lg tmux tmuxp gpg bluetui bc claude codex btop rmpc systemctl)
        AUTO_NOTIFY_EXPIRE_TIME=5000
        AUTO_NOTIFY_CANCEL_ON_SIGINT=0

        HISTFILE="$HOME/.zsh_history"
        HISTSIZE=10000
        SAVEHIST=10000
        setopt append_history hist_expire_dups_first extended_history hist_find_no_dups hist_reduce_blanks glob_dots

        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ${./p10k.zsh}
        source ${pkgs.fetchFromGitHub {
          owner = "MichaelAquilina";
          repo = "zsh-auto-notify";
          rev = "b51c934d88868e56c1d55d0a2a36d559f21cb2ee";
          hash = "sha256-s3TBAsXOpmiXMAQkbaS5de0t0hNC1EzUUb0ZG+p9keE=";
        }}/auto-notify.plugin.zsh
        source ${pkgs.fzf}/share/fzf/key-bindings.zsh
        source ${pkgs.fzf}/share/fzf/completion.zsh
        eval "$(direnv hook zsh)"

        source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      '';
    };
  };
}
