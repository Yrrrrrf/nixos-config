{
  config,
  lib,
  ...
}: {
  config.flake.lib.dev.langs.rust = {
    helix = config.flake.lib.helix.mkLangs {
      name = "rust";
      scope = "source.rust";
      injection-regex = "rs|rust";
      file-types = ["rs"];
      roots = ["Cargo.toml" "Cargo.lock"];
      # comment-tokens (plural) is what rust uses — passes through as extra
      comment-tokens = ["//" "///" "//!"];
      lsp = "rust-analyzer";
      formatter = "rustfmt";
    };
    extraPackages = pkgs:
      with pkgs; [
        (lib.hiPrio rust-analyzer)
        (lib.hiPrio rustfmt)
        rustup
      ];
  };
}
