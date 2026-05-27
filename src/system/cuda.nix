{...}: {
  flake.nixosModules.cuda = {pkgs, ...}: {
    nix.settings = {
      extra-substituters = ["https://cuda-maintainers.cachix.org"];
      extra-trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E="
      ];
    };

    services.ollama = {
      enable = true;
      # acceleration = "cuda";
    };

    # services.open-webui.enable = true;

    programs.nix-ld.libraries = with pkgs; [
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
    ];
  };
}
