# /etc/nixos/system/nvidia.nix
#
# This module centralizes all system-level configuration for NVIDIA GPUs.
# It handles driver installation, kernel modules, unfree package permissions,
# and system-wide library access.

{ pkgs, ... }:

{
  # --- CUDA Maintainers Cachix ---
  # This adds a binary cache that often provides pre-built CUDA packages,
  # which can significantly speed up builds.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [ "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E=" ];
  };

  # --- Unfree Package Permissions ---
  # Allow the installation of the proprietary NVIDIA driver and CUDA components.
  # This is more secure than a global `allowUnfree = true`.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkg.pname or "") [
    "nvidia-x11"
    "nvidia-settings"
    "cudatoolkit"
  ];

  # --- Graphics & NVIDIA Driver Configuration ---
  # Explicit assertion — upstream nixos-hardware ga402x-nvidia sets this
  # transitively via common/gpu/nvidia/prime.nix, but we assert it locally
  # for documentation and grep-ability.
  hardware.graphics.enable = true;

  # NVIDIA driver settings. Upstream handles modesetting, package selection
  # (Ada Lovelace → stable branch), and deliberately leaves powerManagement
  # unset (tested to hang the 4060 on suspend/resume).
  hardware.nvidia = {
    # Use the proprietary kernel module (not the open-source variant).
    open = false;
  };

  # --- Nix-LD for Non-Nix Binaries ---
  # This helps applications that are not built with Nix (like some downloaded
  # binaries or Python packages with native extensions) find essential libraries
  # from the Nix store. This is a robust fallback mechanism.
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add the core NVIDIA driver libraries to the system-wide library path.
    linuxPackages.nvidia_x11
  ];
}
