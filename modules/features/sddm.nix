{ self, inputs, ... }: {
  flake.nixosModules.sddm = { pkgs, ... }:
    let
      sddm-astronaut = pkgs.sddm-astronaut.override {
        embeddedTheme = "hyprland_kath";
        themeConfig = {
          Blur = 1.0;
          BlurMax = 64;
          FormPosition = "left";
          Font = "Jersey 10";
          FontSize = 20;
          HideSystemButtons = false;
          HideVirtualKeyboard = true;
        };
      };
      sddmDependencies = with pkgs; [
        sddm-astronaut
        kdePackages.qtmultimedia
        google-fonts
      ];
    in {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        theme = "sddm-astronaut-theme";
        extraPackages = sddmDependencies;
      };
      security.pam.services = {
        sddm = {
          gnupg = {
            enable = true;
            storeOnly = true;
          };
          enableGnomeKeyring = true;
        };
        sddm-greeter = {
          gnupg = {
            enable = true;
            storeOnly = true;
          };
          enableGnomeKeyring = true;
        };
      };
    };
}
