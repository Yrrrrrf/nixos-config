# /etc/nixos/modules/system/podman.nix
# A shareable module for Podman configuration, inspired by the video.

{ config, pkgs, lib, ... }:

{
  # This creates a new option `services.podman.enable`
  options.services.podman.enable = lib.mkEnableOption "Enable Podman services";

  config = lib.mkIf config.services.podman.enable {
    # This block will only be active if `services.podman.enable = true;` is set.

    virtualisation = {
      podman = {
        enable = true;
        # Creates a `docker` alias for podman.
        dockerCompat = true;
        # Allows containers to resolve each other by name.
        defaultNetwork.settings.dns_enabled = true;

        # Automatically clean up unused images weekly.
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };
    };

    # Install podman-compose system-wide for managing container stacks.
    environment.systemPackages = with pkgs; [
      podman-compose
      podman-tui
    ];
  };
}
