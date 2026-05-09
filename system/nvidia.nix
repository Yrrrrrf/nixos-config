# /etc/nixos/system/nvidia.nix
#
# This module centralizes all system-level configuration for NVIDIA GPUs.
# It handles driver installation, kernel modules, unfree package permissions,
# and system-wide library access.

{ pkgs, ... }:

{

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
    open = true;
    # open = false;
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

  # --- Stable DRM Symlinks for PRIME Offload ---
  # Create colon-free symlinks so AQ_DRM_DEVICES (which splits on ':')
  # can reference cards without shattering on PCI addresses.
  #   /dev/dri/igpu → AMD iGPU (card1, PCI 0000:65:00.0)
  #   /dev/dri/dgpu → NVIDIA dGPU (card0, PCI 0000:01:00.0)
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:65:00.0", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"
  '';
}
