{
  description = "A modular development environment for Rust";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay"; # For easy toolchain selection
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      system = "x86_64-linux";
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs { inherit system overlays; };

      # Use the stable toolchain from the rust-overlay by default
      rustToolchain = pkgs.rust-bin.stable.latest.default;

      # --- Import the dependency sets you need for this project ---
      hardwareDeps = import ./deps/hardware.nix { inherit pkgs; };
      bevy = import ./deps/bevy.nix { inherit pkgs; };
      webDeps = import ./deps/web.nix { inherit pkgs; };

    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          rustToolchain
        ]
          # ++ hardwareDeps
          # ++ bevy
          # ++ webDeps
        ;
      };
    };
}
