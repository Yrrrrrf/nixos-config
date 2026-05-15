{ config, ... }:
{
  config.flake.lib.dev.langs.nix = {
    helix = config.flake.lib.helix.mkLangs {
      name = "nix";
      scope = "source.nix";
      file-types = [ "nix" ];
      comment-token = "#";
      lsp = "nil";
      formatter = "alejandra";
    };
    extraPackages =
      pkgs: with pkgs; [
        nil
        alejandra
        statix
        deadnix
        flake-checker
      ];
  };
}
