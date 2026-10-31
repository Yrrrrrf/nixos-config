{...}: {
  flake.nixosModules.llms = {pkgs, ...}: {
    services.ollama = {
      enable = true;
      # Build CUDA kernels only for RTX 4060 Laptop GPU (Ada Lovelace, sm_89)
      # instead of all 10 default architectures.
      package = pkgs.ollama-cuda.override {
        cudaArches = ["89"];
      };
    };

    services.open-webui = {
      enable = true;
      # Skip fpdf2's 6-min pytest suite: test_image_with_explicit_dimensions
      # fails with a PDF MD5 mismatch in nixpkgs, and cache.nixos.org already
      # serves the prebuilt binary when doCheck = false.
      package = pkgs.open-webui.overridePythonAttrs (old: {
        dependencies =
          map (
            dep:
              if (dep.pname or "") == "fpdf2"
              then dep.overridePythonAttrs {doCheck = false;}
              else dep
          )
          old.dependencies;
      });
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
