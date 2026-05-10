{pkgs, ...}: {
  programs.helix.languages.language = [
    {
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
    }
  ];
  programs.helix.languages.language-server.sqls = {
    command = "sqls";
  };
  home.packages = with pkgs; [sqls];
}
