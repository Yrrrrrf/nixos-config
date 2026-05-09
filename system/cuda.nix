# /etc/nixos/system/cuda.nix
#
# This module centralizes all CUDA workloads, applications, and required runtime libraries.

{ pkgs, ... }:

{
  # --- CUDA Maintainers Cachix ---
  # Provides pre-built CUDA packages to speed up builds.
  nix.settings = {
    extra-substituters = [ "https://cuda-maintainers.cachix.org" ];
    extra-trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E="
    ];
  };

  # --- Local AI Services ---
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  services.open-webui.enable = true;

  # --- Runtime Libraries ---
  # Essential packages needed at RUNTIME for CUDA applications via nix-ld
  programs.nix-ld.libraries = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
  ];
}
