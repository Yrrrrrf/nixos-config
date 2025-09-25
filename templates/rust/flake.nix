# /etc/nixos/templates/flake-rust.nix
# ===================================================================
# A Universal Rust Development Flake
#
# Combines best practices for a fast, reproducible, and easy-to-use
# Rust development environment with Nix.
# ===================================================================
{
  description = "A universal development environment for Rust projects";

  # --- Flake Inputs ---
  # All external dependencies are pinned here for reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    naersk.url = "github:nix-community/naersk";

    # --- Efficiency Tip ---
    # Ensure rust-overlay and naersk use the same nixpkgs to avoid duplicate downloads.
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  # --- Flake Outputs ---
  # Defines what this flake provides: shells, packages, and the template itself.
  outputs = { self, nixpkgs, rust-overlay, naersk }:
    let
      system = "x86_64-linux";
      overlays = [ rust-overlay.overlays.default ];
      pkgs = import nixpkgs { inherit system overlays; };

      # The default Rust toolchain provided by the rust-overlay.
      # You can easily change "stable" to "nightly" or a specific version.
      rustToolchain = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ]; # rust-src is required for rust-analyzer
      };

      # A helper library for fast, cached Rust builds.
      naersk-lib = pkgs.callPackage naersk { };

      # ===================================================================
      # --- Centralized Dependency Sets ---
      #
      # Instead of importing from a `deps` folder, all common dependency
      # sets are defined here. Simply uncomment the set you need in the
      # devShells below.
      # ===================================================================

      # Dependencies for Bevy game engine development.
      bevyDeps = with pkgs; [
        alsa-lib
        libxkbcommon
        wayland
        xorg.libX11
        xorg.libXcursor
        pkg-config
        cargo-watch # For hot-reloading
      ];

      # Dependencies for hardware/embedded development (example for ARM).
      hardwareDeps = with pkgs; [
        pkgsCross.armv7l-hf-multiplatform.stdenv.cc
        openocd
        gdb
      ];

      # Dependencies for WebAssembly (WASM) development.
      webDeps = with pkgs; [
        wasm-pack
        cargo-watch
      ];

      # Dependencies for projects using GTK4.
      gtkDeps = with pkgs; [
        gtk4
        glib
        pkg-config
      ];

    in
    {
      # ===================================================================
      # --- Development Shells ---
      # These are the environments you will enter with `nix develop`.
      # ===================================================================
      devShells.${system} = {

        # The default shell: A complete environment for most CLI/backend projects.
        # To use: `nix develop`
        default = pkgs.mkShell {
          buildInputs = [
            rustToolchain
            pkgs.pkg-config # Often needed for -sys crates
            pkgs.openssl    # A very common dependency for web projects

            # --- UNCOMMENT THE DEPENDENCY SET YOU NEED ---
            # ++ bevyDeps
            # ++ hardwareDeps
            # ++ webDeps
            # ++ gtkDeps
          ];

          # This environment variable is required by rust-analyzer.
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";

          shellHook = ''
            echo "✅ Entered Rust Shell"
            echo "Hint: Use 'nix build .#dev' for fast, cached builds during development."
          '';
        };
      };

      # ===================================================================
      # --- Packages ---
      # These define how to build your project for distribution or running.
      # ===================================================================
      packages.${system} = {

        # The standard, highly reproducible build.
        # Use this for final builds.
        # To build: `nix build`
        # To run: `nix run`
        default = pkgs.rustPlatform.buildRustPackage {
          pname = "my-rust-project"; # <-- TODO: Change this to your project name
          version = "0.1.0";

          src = ./.;

          # This line makes Nix handle all crate dependencies automatically
          # based on your `Cargo.lock` file.
          cargoLock.lockFile = ./Cargo.lock;

          # You may need to add system build dependencies here too.
          nativeBuildInputs = [ pkgs.pkg-config ];
          # buildInputs = [ pkgs.openssl ];
        };

        # A faster, cached build for quick iteration during development.
        # To build: `nix build .#dev`
        # To run: `nix run .#dev`
        dev = naersk-lib.buildPackage {
          src = ./.;
          # Note: No need to specify cargoLock, Naersk finds it automatically.
        };
      };

      # ===================================================================
      # --- Template Definition ---
      # This makes `nix flake init -t /path/to/this/template` work.
      # ===================================================================
      templates.default = {
        path = ./.;
        description = "A universal Rust project flake";
      };
    };
}
