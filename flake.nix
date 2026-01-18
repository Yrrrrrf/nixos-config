# /etc/nixos/flake.nix
{
  description = "yrrrrrf's stable NixOS configuration with select unstable packages";

  # --- Flake Inputs ---
  # All external dependencies are pinned here for full reproducibility.
  inputs = {
    # Our base system will be the stable NixOS 25.11 release.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # We also bring in the unstable channel specifically for newer packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager should follow our primary (stable) nixpkgs to avoid conflicts.
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  # --- Flake Outputs ---
  # The 'outputs' function takes all 'inputs' as arguments.
  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, nixos-hardware, ... } @ inputs:

    let
      # Define shared variables for all outputs.
      system = "x86_64-linux";
      username = "yrrrrrf";
      lib = nixpkgs.lib;

      unstable-packages-overlay = final: prev:
        let
          # Import the unstable package set
          unstable = import nixpkgs-unstable {
            inherit system;
            config = {
              allowUnfree = true;
              # permittedInsecurePackages = [
                # "libxml2-2.13.8"
                # "ciscoPacketTracer8-8.2.2"
                 # ];
            };
          };
        in
        {
          # Your other unstable packages
          uv = unstable.uv;
          deno = unstable.deno;
          bun = unstable.bun;
          
          # THIS IS THE ORIGINAL METHOD. NO overrideAttrs, NO sha256.
          # We are simply passing the local file path to the expected argument.
          # ciscoPacketTracer8 = unstable.ciscoPacketTracer8.override {
            # packetTracerSource = ./assets/Packet_Tracer822_amd64_signed.deb;
          # };
        };

    in {
      # --- NixOS System Configurations ---
      nixosConfigurations = {
        
        # The hostname of your machine.
        "g14" = lib.nixosSystem {
          inherit system;
          
          # 'specialArgs' makes 'inputs' and 'username' available to all our modules.
          specialArgs = { inherit inputs username; };

          modules = [
            # CRITICAL: The overlay must be applied first.
            # This ensures that every other module sees the modified package set.
            { nixpkgs.overlays = [ unstable-packages-overlay ]; }

            # The main entry point for this specific host
            ./host/g14/configuration.nix

            # Make Home Manager available to the system
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;

              # Pass the same specialArgs to Home Manager modules
              home-manager.extraSpecialArgs = { inherit inputs username; };

              # Import the desired Home Manager user profile
              # home-manager.users.${username} = import ./home/profiles/default.nix;
              home-manager.users.${username} = import ./home/profiles/dev.nix;
            }
          ];
        };
      };
    };
}
