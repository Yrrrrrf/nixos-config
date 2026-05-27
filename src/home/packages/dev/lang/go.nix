{config, ...}: {
  config.flake.lib.dev.langs.go = {
    helix = config.flake.lib.helix.mkLangs {
      name = "go";
      scope = "source.go";
      file-types = ["go"];
      roots = ["go.work" "go.mod"];
      comment-token = "//";
      lsp = "gopls";
      formatter = "gofmt";
      indent = {
        tab-width = 4;
        unit = "\t";
      };
    };
    extraPackages = pkgs: with pkgs; [gopls go];
  };
}
