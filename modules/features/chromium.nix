{...}: {
  flake.nixosModules.chromium = {
    config,
    lib,
    pkgs,
    ...
  }: let
    commandLineArgs = lib.concatStringsSep " " [
      "--password-store=gnome-libsecret"
      "--enable-features=MiddleClickAutoscroll"
      "--extension-mime-request-handling=always-prompt-for-install"
      "--webrtc-ip-handling-policy=default_public_interface_only"
    ];
    ungoogled-chromium = pkgs.ungoogled-chromium.override {inherit commandLineArgs;};
  in {
    environment.systemPackages = [ungoogled-chromium];

    preservation = {
      preserveAt."/persistent" = {
        users.${config.preferences.user.name} = {
          directories = [
            ".config/chromium"
          ];
        };
      };
    };
  };
}
