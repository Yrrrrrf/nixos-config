{...}: {
  flake.nixosModules.services = {
    config,
    pkgs,
    ...
  }: {
    services = {
      podman.enable = true;

      blueman.enable = true;
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };

    # --- Graphical Session & Desktop Services ---
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    security.pam.services.hyprlock = {};

    xdg.portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
    };

    # --- Core System Services ---
    services.udisks2.enable = true;
    services.pipewire.enable = true;
    security.rtkit.enable = true;
    services.openssh.enable = true;
  };
}
