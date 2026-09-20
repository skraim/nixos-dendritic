{...}: {
  flake.nixosModules.openlogi = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.openlogi
    ];

    services.udev.packages = [pkgs.openlogi];
  };
}
