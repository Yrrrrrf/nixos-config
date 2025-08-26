# /etc/nixos/modules/system/core.nix
#
# This module configures the core, fundamental aspects of the NixOS system.
# It includes the bootloader, time and language settings, and essential
# packages that should be available to all users on the system.

{ config, pkgs, ... }:

{
  # --- System Bootloader Configuration ---
  # Defines how the system starts up. systemd-boot is a modern, simple
  # boot manager for UEFI systems.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true; # Required for systemd-boot to manage boot entries.
  boot.loader.systemd-boot.configurationLimit = 10; # Limits the number of old generations kept.

  # --- Timezone and Internationalisation Settings ---
  # Ensures the system clock and user-facing text are correctly configured.
  time.timeZone = "America/Mexico_City";
  i18n.defaultLocale = "en_US.UTF-8";

  # --- Nix-LD ---
  # Provides a wrapper for dynamically linked executables that are not in the Nix store,
  # allowing them to find necessary libraries.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib

      linuxPackages.nvidia_x11
    ];
  };

  # --- System-wide Packages ---
  # These packages are installed into the global system profile, making them
  # available to all users on the system. This is best for system-level tools.
  environment.systemPackages = with pkgs; [
    git       # Version control system, essential for development.
    vim       # A highly configurable text editor.
    asusctl   # Utility for managing ASUS laptop features (e.g., fan profiles, keyboard backlight).

    exfatprogs # Provides tools for the exFAT filesystem, useful for external drives.

    # --- Temporary debugging tools here ---
    #mesa-demos # Provides the 'eglinfo' command
    #nvtop      # The GPU process monitor
  ];
}
