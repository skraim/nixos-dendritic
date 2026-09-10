# {inputs, ...}: {
#   perSystem = {pkgs, ...}: {
#     packages.quickshell = inputs.wrappers.lib.wrapPackage {
#       inherit pkgs;
#       package = pkgs.quickshell;
#       runtimeInputs = with pkgs; [
#         qt6.qt5compat
#         qt6.qtquick3d
#         qt6.qtwayland
#         qt6.qtdeclarative
#         qt6.qtsvg
#         qtcreator
#         kdePackages.qtmultimedia
#       ];
#       flags = {
#         "-p" = ./.;
#       };
#       env = {
#         QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
#       };
#     };
#   };
# }

{inputs, ...}: {
  perSystem = {pkgs, ...}: 
    let
    wrapped = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.quickshell;
      runtimeInputs = with pkgs; [
        qt6.qt5compat
        qt6.qtquick3d
        qt6.qtwayland
        qt6.qtdeclarative
        qt6.qtsvg
        # qtcreator
        kdePackages.qtmultimedia
      ];
      # env = {
      #   # theme.nix is the single source of truth; Common/Theme.qml loads this.
      #   "QS_FLAKE_THEME_FILE" = pkgs.writeText "quickshell-theme.json" (builtins.toJSON self.theme);
      #   # Qt 6 blocks XHR on file:// by default; Theme.qml needs it.
      #   "QML_XHR_ALLOW_FILE_READ" = "1";
      # };
      flags = {
        "-c" = toString ./.;
      };
      env = {
        QML2_IMPORT_PATH = "${pkgs.qt6.qt5compat}/lib/qt-6/qml:${pkgs.qt6.qtbase}/lib/qt-6/qml";
      };
    };
  in {
    packages.quickshell = pkgs.symlinkJoin {
      name = "quickshell-wrapped";
      paths = [wrapped];
      postBuild = ''
        rm $out/bin/qs
        ln -s $out/bin/quickshell $out/bin/qs
      '';
      meta = (wrapped.meta or {}) // {mainProgram = "quickshell";};
    };
    # packages.quickshellWrapped = inputs.wrappers.lib.wrapPackage {
    #
    #   inherit pkgs;
    #   package = pkgs.quickshell;
    #   runtimeInputs = [
    #     pkgs.zoxide
    #   ];
    #   flags = {
    #     "-c" = toString ./.;
    #   };
    # };
  };
}

