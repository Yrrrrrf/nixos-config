{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "sql";
  language = {
    name = "sql";
    scope = "source.sql";
    file-types = ["sql" "dsql"];
    comment-token = "--";
    language-servers = ["sqls"];
    block-comment-tokens = {
      start = "/*";
      end = "*/";
    };
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    auto-format = false;
  };
  servers.sqls.command = "sqls";
  extraPackages = pkgs: [pkgs.sqls];
}
