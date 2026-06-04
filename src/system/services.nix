{...}: {
  flake.nixosModules.services = {pkgs, ...}: {
    services = {
      podman.enable = true;
    };

    # todo: Check the bluetooth once changed to AX210
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
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
