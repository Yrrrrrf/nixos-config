{...}: {
  flake.nixosModules.nvidia = {pkgs, ...}: {
    hardware.graphics.enable = true;

    hardware.nvidia = {
      open = true;
    };

    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      linuxPackages.nvidia_x11
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:65:00.0", SYMLINK+="dri/igpu"
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"
    '';
  };
}
