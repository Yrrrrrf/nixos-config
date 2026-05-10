{...}: {
  flake.nixosModules.podman = {
    config,
    pkgs,
    lib,
    ...
  }: {
    options.services.podman.enable = lib.mkEnableOption "Enable Podman services";

    config = lib.mkIf config.services.podman.enable {
      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      users.users.yrrrrrf.extraGroups = ["podman"];

      environment.systemPackages = with pkgs; [
        podman-compose
        podman-tui
        kubernetes
        traefik
        lazydocker
      ];

      programs.zsh.shellAliases.lp = "lazydocker";
    };
  };
}
