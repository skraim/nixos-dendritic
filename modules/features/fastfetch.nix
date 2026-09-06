{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.fastfetch = inputs.wrapper-modules.wrappers.fastfetch.wrap {
      inherit pkgs;
      settings = {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "small";
          padding = {
            top = 4;
            right = 3;
          };
        };
        display = {
          separator = ">  ";
          color = {
            separator = "red";
          };
          constants = [
            "───────────────────────────────────────────────────────────────────────────"
            "│\u001b[75C│\u001b[75D"
          ];
        };
        modules = [
          {
            format = "{\#1}{\#keys}╭{$1}╮\u001b[76D {user-name-colored}{at-symbol-colored}{host-name-colored} 🖥  ";
            type = "title"
          }
          {
            key = "{$2}{\#31}󰇄 host     ";
            type = "host";
          }
          {
            key = "{$2}{\#32}{icon} distro   ";
            type = "os";
          }
          {
            key = "{$2}{\#33} kernel   ";
            type = "kernel";
          }
          {
            key = "{$2}{\#35} wm       ";
            type = "wm";
          }
          {
            key = "{$2}{\#36} term     ";
            type = "terminal";
          }
          {
            key = "{$2}{\#31} shell    ";
            type = "shell";
          }
          {
            key = "{$2}{\#32}󰍛 cpu      ";
            type = "cpu";
          }
          {
            key = "{$2}{\#33}󰍛 gpu      ";
            type = "gpu";
          }
          {
            key = "{$2}{\#34} memory   ";
            type = "memory";
          }
          {
            key = "{$2}{\#35}󰉉 disk     ";
            type = "disk";
            folders = "/:/run/media/artem/backup";
          }
          {
            format = "{\#1}{\#keys}├{$1}┤";
            type = "custom";
          }
          {
            key = "{$2}{\#36} colors   ";
            type = "colors";
            symbol = "circle";
          }
          {
            format = "{\#1}{\#keys}╰{$1}╯";
            type = "custom";
          }
        ];
      };
    };
  };
}
