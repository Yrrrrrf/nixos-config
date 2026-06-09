{...}: {
  flake.nixosModules.llms = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      # acceleration = "cuda";
    };

    services.open-webui.enable = true;

    environment.systemPackages = [
      pkgs.n8n
    ];
  };
}
