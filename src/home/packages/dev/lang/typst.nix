{config, ...}: {
  config.flake.lib.dev.langs.typst = {
    helix = config.flake.lib.helix.mkLangs {
      name = "typst";
      file-types = ["typ"];
      lsp = "tinymist";
      formatter = "typstyle";
    };
    extraPackages = pkgs: with pkgs; [tinymist typstyle typst];
  };
}
