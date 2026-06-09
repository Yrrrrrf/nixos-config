{...}: {
  flake.nixosModules.llms = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      acceleration = "cuda";
    };

    services.open-webui.enable = true;

    environment.systemPackages = [
      pkgs.n8n
    ];
  };
}
