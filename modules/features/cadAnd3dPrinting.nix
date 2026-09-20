{...}: {
  flake.nixosModules.cadAnd3dPrinting = {
    config,
    pkgs,
    ...
  }: {
    hardware.spacenavd.enable = true;

    environment.systemPackages = with pkgs; [
      spnavcfg
      freecad
      prusa-slicer
      orca-slicer
    ];

    preservation = {
      preserveAt."/persistent" = {
        users.${config.preferences.user.name} = {
          directories = [
            ".config/PrusaSlicer"
            ".config/OrcaSlicer"
            ".config/FreeCAD"
          ];
        };
      };
    };
  };
}
