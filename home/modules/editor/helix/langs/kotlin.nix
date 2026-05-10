{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "kotlin";
      scope = "source.kotlin";
      file-types = ["kt" "kts"];
      comment-token = "//";
      language-servers = ["kotlin-language-server"];
      auto-format = false;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      formatter = {
        command = "ktlint";
        args = ["--format" "--stdin"];
      };
    }
  ];
  programs.helix.languages.language-server.kotlin-language-server = {
    command = "kotlin-language-server";
  };
  home.packages = with pkgs; [kotlin-language-server ktlint];
}
