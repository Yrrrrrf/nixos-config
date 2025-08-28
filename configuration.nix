# /etc/nixos/configuration.nix
#
# This is the main entry point for the NixOS system configuration.
# Its primary role is to import all the necessary modules that define the system,
# including hardware, core settings, services, and user environments.

{ config, lib, pkgs, ... }:

let
  user = import ./user.nix;

  # Pin external dependencies to ensure reproducible builds across machines and time.
  # Using fetchTarball is good; migrating to Flakes is the next evolution.
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz";
  nixos-hardware = builtins.fetchTarball "https://github.com/NixOS/nixos-hardware/archive/master.tar.gz";
in
{
  # --- Module Imports ---
  imports = [
    ./hardware-configuration.nix
    ./networking.nix

    # External modules that provide additional functionality.
    (import "${home-manager}/nixos") # Integrates Home Manager into NixOS.
    (import "${nixos-hardware}/asus/zephyrus/ga402x/nvidia") # Laptop-specific hardware support.
    (import "${nixos-hardware}/asus/zephyrus/ga402x/amdgpu")
    
    # ---> Our New Modular Structure <---
    # These paths point to the modules we will create in the next steps.
    ./modules/system/core.nix      # Bootloader, timezone, locale, system packages.
    ./modules/system/fonts.nix     # System-wide font configuration.
    ./modules/system/services.nix  # System daemons like Pipewire, PostgreSQL, etc.
    ./modules/system/podman.nix    # podman & containers...
  ];

  # --- Global System Settings ---
  # A few top-level settings that are fundamental to the whole system.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow the installation of proprietary packages.
  nixpkgs.config.allowUnfree = true;

  services.podman.enable = true;

  nixpkgs.overlays = [
    (final: prev:
      let
        unstable = import <unstable> {
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              # required by ciscoPacketTracer -> remove when no longer needed
              "libxml2-2.13.8"
            ];
          };
        };
      in
      {
        ollama = unstable.ollama;

        ciscoPacketTracer8 = unstable.ciscoPacketTracer8.override {
          packetTracerSource = ./assets/Packet_Tracer822_amd64_signed.deb;
        };
      }
    )
  ];

  # 1. Allow proprietary NVIDIA drivers to be installed.
  # We use a predicate to only allow specific packages for security.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or "") [
    "nvidia-x11"
    "nvidia-settings"
    # Add the CUDA packages required by Ollama
    "cuda_cudart"
    "libcublas"
  ];

  # 2. Enable OpenGL and the NVIDIA graphics driver.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  # 3. Configure the NVIDIA driver.
  hardware.nvidia = {
    # Use the open-source kernel module, recommended for RTX 20-series and newer.
    #prime = {
    #  offload.enable = true;
    #  # Get the bus using: `lspci | grep -i vg`
    #  amdgpuBusId = "PCI:65:0:0";
    #  nvidiaBusId = "PCI:1:0:0";
    #};
 
    open = true;

    # Enable Nvidia settings and power management.
    nvidiaSettings = true;
    powerManagement.enable = true;
  };

  # 4. Enable the Ollama service and turn on CUDA acceleration.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E=" ];
  };

  # Define the system user account. This is a prerequisite for Home Manager.
  users.users.${user.username} = {
    isNormalUser = true;
    description = user.username;
    extraGroups = [
      "wheel"
      "networkmanager"
      "input"
      # "video"
      # "render"
     ];
    shell = pkgs.zsh;
    # This is often needed when Zsh is configured by Home Manager.
    ignoreShellProgramCheck = true;
  };

  # --- Home Manager Integration ---
  # This section hooks Home Manager into the NixOS build process, telling it
  # which user to manage and where to find their configuration.
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    backupFileExtension = "backup";
    users.${user.username} = import ./home/home.nix;
  };

  #nix.gc.automatic = true;
  #nix.gc.dates = "weekly";

  # --- System Version ---
  # This is crucial for ensuring smooth upgrades. Do not change this value
  # until you have read the NixOS release notes for the new version.
  system.stateVersion = "25.05";
}
