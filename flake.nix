# /etc/nixos/flake.nix
{
  description = "yrrrrrf's stable NixOS configuration with select unstable packages";

  # --- Flake Inputs ---
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  # --- Flake Outputs ---
  outputs = inputs@{ flake-parts, ... }: flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" ];

    imports = [
      inputs.home-manager.flakeModules.home-manager
      (inputs.import-tree ./src)
    ];

    # TEMPORARY BRIDGE
    # This keeps the system building from the old paths until the refactor completes.
    flake.nixosConfigurations."g14" = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; username = "yrrrrrf"; };
      modules = [
        {
          nixpkgs.overlays = [
            (final: prev:
              let
                unstable = import inputs.nixpkgs-unstable {
                  system = "x86_64-linux";
                  config = {
                    allowUnfree = true;
                    permittedInsecurePackages = [ "libxml2-2.13.9" ];
                  };
                };
                unstablePackages = import ./unstable.nix;
              in
                inputs.nixpkgs.lib.mapAttrs (name: override:
                  if override == null then unstable.${name}
                  else override unstable.${name}
                ) unstablePackages
            )
          ];
        }
        ./host/g14/configuration.nix
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; username = "yrrrrrf"; };
          # The temporary bridge preserves the previous profile
          home-manager.users.yrrrrrf = import ./home/profiles/dev.nix;
        }
      ];
    };
  };
}
