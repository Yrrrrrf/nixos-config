{config, ...}: {
  config.flake.lib.dev.langs.just = {
    helix = config.flake.lib.helix.mkLangs {
      name = "just";
      scope = "source.just";
      file-types = ["Justfile" "just"];
      comment-token = "#";
      lsp = "just-lsp";
      formatter = {
        command = "just";
        args = ["--fmt" "--unstable"];
      };
    };
    extraPackages = pkgs: with pkgs; [just-lsp just];
  };
}
