# /etc/nixos/templates/flake-python.nix
# ===================================================================
# A Universal Python Development Flake with uv
#
# Combines best practices for a fast, reproducible, and easy-to-use
# Python development environment with Nix and uv package manager.
# ===================================================================
{
  description = "A universal development environment for Python projects using uv";

  # --- Flake Inputs ---
  # All external dependencies are pinned here for reproducibility.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  # --- Flake Outputs ---
  # Defines what this flake provides: shells, packages, and the template itself.
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # ===================================================================
      # --- Centralized Dependency Sets ---
      #
      # All common dependency sets are defined here. Simply uncomment 
      # the set you need in the devShells below.
      # ===================================================================

      # Dependencies for Pygame projects
      pygameDeps = with pkgs; [
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        SDL2_gfx
      ];

      # Dependencies for Qt/GUI applications (PyQt/PySide)
      qtDeps = with pkgs; [
        qt6.qtbase
        qt6.qtwayland
        xorg.libxcb
        glib
      ];

    in
    {
      # ===================================================================
      # --- Development Shells ---
      # These are the environments you will enter with `nix develop`.
      # ===================================================================
      devShells.${system} = {

        # The default shell: A complete environment for most Python projects.
        # To use: `nix develop`
        default = pkgs.mkShell {
          buildInputs = [
            pkgs.uv  # Fast Python package manager - uv handles Python itself

            # --- UNCOMMENT THE DEPENDENCY SET YOU NEED ---
            # ++ pygameDeps
            # ++ qtDeps
          ];
        };
      };

      # ===================================================================
      # --- Template Definition ---
      # This makes `nix flake init -t /path/to/this/template` work.
      # ===================================================================
      templates.default = {
        path = ./.;
        description = "A universal Python project flake with uv";
      };
    };
}
