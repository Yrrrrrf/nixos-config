# /etc/nixos/templates/go/flake.nix
{
  description = "A development environment for Go projects";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # The Go toolchain
          go

          # Language server for Helix/VSCode
          gopls

          # A popular linter
          golangci-lint
        ];
      };
    };
}
