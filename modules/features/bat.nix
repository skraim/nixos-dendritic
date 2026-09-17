{ inputs, ... }: {
  perSystem = { pkgs, ... }: {
    packages.bat =
      (inputs.wrappers.wrapperModules.bat.apply {
        inherit pkgs;
        "bat-config".content = ''
          --style=plain
        '';
      }).wrapper;
  };
}
