{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "toml";
      scope = "source.toml";
      file-types = ["toml"];
      comment-token = "#";
      language-servers = ["taplo"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "taplo";
        args = ["format" "-"];
      };
      auto-format = false;
    }
  ];
  programs.helix.languages.language-server.taplo = {
    command = "taplo";
    args = ["lsp" "stdio"];
  };
  home.packages = with pkgs; [taplo];
}
