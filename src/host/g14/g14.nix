{inputs, ...}: {
  config.flake.lib.hosts.g14 = {
    hostname = "g14";
    system = "x86_64-linux";
    user = "yrrrrrf";
    stateVersion = "25.11";

    hardwareConfig = ./hardware-configuration.nix;
    hardwareModule = inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia;

    modules = [
      # Inline unstable overlay — stays host-local for now.
      {
        nixpkgs.overlays = [
          (
            _final: _prev: let
              unstable = import inputs.nixpkgs-unstable {
                system = "x86_64-linux";
                config = {
                  allowUnfree = true;
                  permittedInsecurePackages = ["libxml2-2.13.9"];
                };
              };
              unstablePackages = import ../../../unstable.nix;
            in
              inputs.nixpkgs.lib.mapAttrs (
                name: override:
                  if override == null
                  then unstable.${name}
                  else override unstable.${name}
              )
              unstablePackages
          )
        ];
      }

      # G14-specific extras: asusctl userland package + asusd service.
      (
        {pkgs, ...}: {
          environment.systemPackages = [pkgs.asusctl];
          services.asusd = {
            enable = true;
            enableUserService = true;
          };
          # Linux 7! :D
          boot.kernelPackages = pkgs.linuxPackages_latest;
          boot.kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ];
        }
      )

      # Named modules from the dendritic registry.
      "g14-networking"
      "core"
      "fonts"
      "services"
      "podman"
      "nvidia"
      "cuda"
      "nh"
      "specialisations-dev"
      "specialisations-minimal"
    ];

    # Host-specific home-manager content. Imported by flake.nixosModules.host
    # via `lib.optional (host ? homeExtras) host.homeExtras`. Hosts that omit
    # this field cause no error.
    homeExtras = {...}: {
      home.file = {
        ".local/bin/kbd-backlight" = {
          source = ./scripts/kbd-backlight.nu;
          executable = true;
        };
        ".local/bin/gpu-performance" = {
          source = ./scripts/gpu-performance.nu;
          executable = true;
        };
        ".config/hypr/host-extras.conf".text = ''
          # G14-specific hyprland binds (sourced from main hyprland.conf).
          bindel = ,XF86KbdBrightnessUp, exec, kbd-backlight --up
          bindel = ,XF86KbdBrightnessDown, exec, kbd-backlight --down
          bind = ,XF86Launch4, exec, gpu-performance --change
        '';
      };
    };
  };

  config.flake.nixosConfigurations.g14 = inputs.self.lib.mkHost inputs.self.lib.hosts.g14;
}
