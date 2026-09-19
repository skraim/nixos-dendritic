{self, ...}: {
  flake.nixosModules.playstationNixosConfiguration = {
    config,
    pkgs,
    ...
  }: {
    imports = [
      self.nixosModules.playstationNixosHardware
      self.diskoConfigurations.playstationNixos
      self.nixosModules.preservation
    ];

    users.users.artem = {
      isNormalUser = true;
      description = "artem";
      extraGroups = ["networkmanager" "wheel" "dialout" "ydotool"];
      initialPassword = "12345";
    };
    networking = {
      hostName = "ps-nixos";
      networkmanager.enable = true;
    };
    boot = {
      loader = {
        timeout = 2;
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
      kernelPackages = pkgs.linuxPackages_latest;
    };
    hardware.enableRedistributableFirmware = true;
    time.timeZone = "Europe/Kyiv";
    i18n.defaultLocale = "en_US.UTF-8";
    environment.systemPackages = with pkgs; [
      git
      neovim
    ];
    system.stateVersion = "25.05";
  };
}
