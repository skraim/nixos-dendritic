{ self, inputs, ... }: {
  flake.nixosModules.ly = { pkgs, ... }: {
      services.displayManager.ly = {
        enable = true;
        x11Support = false;
        settings = {
          animation = "colormix";
          asterisk = "0x2022";
          bg = "0x00111418";
          clock = "%d.%m.%Y";
          default_input = "password";
          colormix_col1 = "0x004D453A";
          colormix_col2 = "0x00201513";
          colormix_col3 = "0x00073D2D";
          corner_bottom_left = "none";
          bigclock = "en";
        };
      };
      security.pam.services = {
        ly = {
          gnupg = {
            enable = true;
            storeOnly = true;
          };
          enableGnomeKeyring = true;
        };
      };
    };
}
