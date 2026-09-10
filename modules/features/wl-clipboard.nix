{ self, inputs, ... }: {
  flake.nixosModules.wlClipboard = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      wl-clip-persist
      wl-clipboard
      cliphist
    ];
  };
}
