{ inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.btop = inputs.wrapper-modules.wrappers.btop.wrap {
      inherit pkgs;
      settings = {
        color_theme = "TTY";
        theme_background = false;
      };
    };
  };
}
