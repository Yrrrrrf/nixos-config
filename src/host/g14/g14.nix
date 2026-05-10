{inputs, ...}: {
  flake.nixosConfigurations."g14" = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit inputs;
      username = "yrrrrrf";
    };
    modules = [
      {
        nixpkgs.overlays = [
          (
            final: prev: let
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

      ../../../hardware-configuration.nix
      inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

      inputs.self.nixosModules.g14-networking
      inputs.self.nixosModules.core
      inputs.self.nixosModules.fonts
      inputs.self.nixosModules.services
      inputs.self.nixosModules.podman
      inputs.self.nixosModules.nvidia
      inputs.self.nixosModules.cuda
      inputs.self.nixosModules.nh
      inputs.self.nixosModules.specialisations-dev
      inputs.self.nixosModules.specialisations-minimal

      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit inputs;
          username = "yrrrrrf";
        };
      }
      ({
        config,
        pkgs,
        ...
      }: let
        user = inputs.self.lib.users.yrrrrrf;
      in {
        nix.settings.experimental-features = ["nix-command" "flakes"];
        nixpkgs.config.allowUnfree = true;

        users.users.${user.username} = {
          isNormalUser = true;
          description = user.username;
          extraGroups = ["wheel" "networkmanager" "input"];
          shell = pkgs.zsh;
          ignoreShellProgramCheck = true;
        };

        system.stateVersion = "25.11";

        home-manager.users.${user.username} = inputs.self.homeModules.default;
      })
    ];
  };
}
