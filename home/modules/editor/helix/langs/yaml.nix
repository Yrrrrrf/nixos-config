{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "yaml";
      scope = "source.yaml";
      file-types = ["yml" "yaml"];
      comment-token = "#";
      language-servers = ["yaml-language-server"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "prettier";
        args = ["--parser" "yaml"];
      };
      auto-format = false;
    }
  ];
  programs.helix.languages.language-server.yaml-language-server = {
    command = "yaml-language-server";
    args = ["--stdio"];
  };
  home.packages = with pkgs; [yaml-language-server nodePackages.prettier];
}
