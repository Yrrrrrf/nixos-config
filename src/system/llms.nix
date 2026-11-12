{...}: {
  flake.nixosModules.llms = {
    pkgs,
    ...
  }: {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      port = 11434;
      # Build CUDA kernels only for RTX 4060 Laptop GPU (Ada Lovelace, sm_89)
      # instead of all 10 default architectures.
      package = pkgs.ollama-cuda.override {
        cudaArches = ["89"];
      };
    };

    # Allow rpi5 (192.168.100.167) to query Ollama over LAN on TCP 11434.
    networking.firewall = {
      extraCommands = ''
        iptables -A nixos-fw -p tcp -s 192.168.100.167 --dport 11434 -j nixos-fw-accept
      '';
      extraStopCommands = ''
        iptables -D nixos-fw -p tcp -s 192.168.100.167 --dport 11434 -j nixos-fw-accept || true
      '';
    };

    environment.systemPackages = [
      # Upstream nixpkgs has a stale FOD hash for n8n 2.39.6 after pnpm_11
      # updates (unfree package, so Hydra doesn't catch FOD drift).
      (pkgs.n8n.overrideAttrs (old: {
        pnpmDeps = pkgs.fetchPnpmDeps {
          inherit (old) pname version src;
          pnpm = pkgs.pnpm_11;
          fetcherVersion = 4;
          hash = "sha256-kSv/8YxvwCFxrSRTqYHP+TAmDgu5OPbcwolHVIqCGDA=";
        };
      }))
    ];
  };
}
