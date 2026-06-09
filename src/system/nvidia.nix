{...}: {
  flake.nixosModules.nvidia = {pkgs, ...}: {
    nix.settings = {
      extra-substituters = ["https://cuda-maintainers.cachix.org"];
      extra-trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E="
      ];
    };

    hardware = {
      graphics.enable = true;

      nvidia.open = true;
    };

    programs.nix-ld.libraries = with pkgs; [
      linuxPackages.nvidia_x11
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:65:00.0", SYMLINK+="dri/igpu"
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"
    '';
  };
}
