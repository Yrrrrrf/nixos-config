# /etc/nixos/host/g14/configuration.nix
#
# This is the main entry point for the NixOS system configuration.
# Its primary role is to import all the necessary modules that define the system.

{ config, lib, pkgs, inputs, ... }:

let
  # This user data is needed for the specialisations below.
  user = import ../../home/users/yrrrrrf.nix;
in
{
  # --- Module Imports ---
  imports = [
    ./hardware-configuration.nix
    ./networking.nix

    # Hardware support modules
    (inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia)
    (inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-amdgpu)

    # Our modular system configuration
    ../../system/core.nix
    ../../system/fonts.nix
    ../../system/services.nix
    ../../system/podman.nix
    ../../system/nvidia.nix
  ];

  # --- Global System Settings ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # nixpkgs.config.permittedInsecurePackages = [
      # "ciscoPacketTracer8-8.2.2"
  # ];

  # hardware.graphics.enable = true;
  # services.xserver.videoDrivers = ["nvidia"];
  # (Your other specific hardware settings...)


  # --- NixOS Specialisations ---
  # This is now the ONLY place where Home Manager profiles are referenced in this file.
  specialisation = {
    "dev" = {
      configuration = {
        system.nixos.tags = [ "dev" ];
        home-manager.users.${user.username} = import ../../home/profiles/dev.nix;
      };
    };

    "minimal" = {
      configuration = {
        system.nixos.tags = [ "minimal" ];
        home-manager.users.${user.username} = import ../../home/profiles/minimal.nix;
      };
    };
  };

  # Define the system user account using the imported data.
  users.users.${user.username} = {
    isNormalUser = true;
    description = user.username;
    extraGroups = [ "wheel" "networkmanager" "input" ];
    shell = pkgs.zsh;
    ignoreShellProgramCheck = true;
  };

  system.stateVersion = "25.11";
}
