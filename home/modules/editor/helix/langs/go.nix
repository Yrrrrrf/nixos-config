{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "go";
      scope = "source.go";
      file-types = ["go"];
      roots = ["go.work" "go.mod"];
      comment-token = "//";
      language-servers = ["gopls"];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      formatter = {command = "gofmt";};
      auto-format = false;
    }
  ];
  programs.helix.languages.language-server.gopls = {
    command = "gopls";
  };
  home.packages = with pkgs; [gopls];
}
