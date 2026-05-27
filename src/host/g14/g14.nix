{inputs, ...}: {
  config.flake.lib.hosts.g14 = {
    hostname = "g14";
    system = "x86_64-linux";
    user = "yrrrrrf";

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
                  # permittedInsecurePackages = ["libxml2-2.13.9"];
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
          };
          # Linux 7! :D
          boot.kernelPackages = pkgs.linuxPackages_latest;
          boot.kernelParams = ["nvme_core.default_ps_max_latency_us=0"];
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
        ".local/bin/gpu-mode" = {
          source = ./scripts/gpu-mode.nu;
          executable = true;
        };
        ".config/hypr/host-extras.conf".text = ''
          # G14-specific hyprland binds (legacy .conf — kept for 0.52 compat).
          bindel = ,XF86KbdBrightnessUp, exec, kbd-backlight --up
          bindel = ,XF86KbdBrightnessDown, exec, kbd-backlight --down
          bind = ,XF86Launch4, exec, gpu-mode --change
        '';
        # Lua version — loaded by hyprland.lua via pcall(require, "host-extras")
        ".config/hypr/host-extras.lua".text = ''
          -- G14-specific Hyprland 0.55+ binds
          hl.bind("XF86KbdBrightnessUp",   hl.dsp.exec_cmd("kbd-backlight --up"),   { locked = true, repeating = true })
          hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("kbd-backlight --down"), { locked = true, repeating = true })
          hl.bind("XF86Launch4",           hl.dsp.exec_cmd("gpu-mode --change"))
        '';
      };
    };
  };

  config.flake.nixosConfigurations.g14 = inputs.self.lib.mkHost inputs.self.lib.hosts.g14;
}
