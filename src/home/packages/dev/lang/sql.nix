{config, ...}: {
  config.flake.lib.dev.langs.sql = {
    helix = config.flake.lib.helix.mkLangs {
      name = "sql";
      scope = "source.sql";
      file-types = ["sql" "dsql"];
      comment-token = "--";
      lsp = "sqls";
      block-comment-tokens = {
        start = "/*";
        end = "*/";
      };
    };
    extraPackages = pkgs: [pkgs.sqls];
  };
}
