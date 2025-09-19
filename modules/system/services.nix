# /etc/nixos/modules/system/services.nix
#
# This module configures all system-level services (daemons). Centralizing
# service definitions here makes it easy to see what is running on the system.

{ config, pkgs, ... }:

{
  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
  };
  
  # --- Graphical Session & Desktop Services ---
  # These are system-level components required for Hyprland and other
  # Wayland compositors to function correctly.
  programs.hyprland = {
    enable = true;        # Enables the core Hyprland compositor package.
    xwayland.enable = true; # Enables XWayland for running X11 applications.
    withUWSM = true;      # Includes the Universal Wayland Session Manager.
  };

  # Enables the PAM (Pluggable Authentication Modules) service for hyprlock,
  # allowing it to authenticate the user with the system's password.
  security.pam.services.hyprlock = {};

  # The XDG Desktop Portal is a standard for sandboxed applications (like Flatpaks)
  # to request resources from the host system (e.g., file pickers, screen sharing).
  xdg.portal = {
    enable = true;
    config.common.default = "*"; # Sets the default portal implementation.
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ]; # Specific backend for Hyprland.
  };

  # --- Core System Services ---

  # Enables the udisks2 service, which allows users to mount and unmount
  # removable media (like USB drives) without needing root privileges.
  services.udisks2.enable = true;

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  # services.open-webui.enable = true;

  # Enables and configures the PostgreSQL database service.
  services.postgresql = {
    enable = false;
    # enable = true;
    package = pkgs.postgresql_17;
    ensureDatabases = [ "mydatabase" ];
    authentication = pkgs.lib.mkOverride 10 ''
      #type database  DBuser  auth-method
      local all       all     trust
    '';
  };

  # Pipewire is a modern, low-latency audio and video server.
  services.pipewire = {
    enable = true;
  };

  # The Real-Time Kit (rtkit) daemon allows services like Pipewire to safely
  # acquire real-time scheduling priorities for low-latency performance.
  security.rtkit.enable = true;

  # Enables the OpenSSH daemon, allowing for secure remote shell access.
  services.openssh.enable = true;
}
