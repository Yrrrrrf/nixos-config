{...}: {
  flake.nixosModules.podman = {
    pkgs,
    lib,
    user,
    ...
  }: {
    options.services.podman.enable = lib.mkEnableOption "Enable Podman services";

    config = {
      services.podman.enable = true;

      virtualisation.podman = {
        enable = true;
        dockerCompat = true;
        dockerSocket.enable = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
        };
      };

      users.users.${user.username}.extraGroups = ["podman"];

      environment.systemPackages = with pkgs; [
        podman-compose
        podman-tui
        kubernetes
        traefik
        lazydocker
      ];
    };
  };
}
