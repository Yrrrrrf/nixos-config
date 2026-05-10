{ pkgs, ... }:
{
  programs.helix.languages.language = [{
    name = "markdown";
    scope = "source.markdown";
    file-types = ["md"];
    language-servers = [ "markdown-oxide" ];
    formatter = { command = "dprint"; args = ["fmt" "--stdin" "md"]; };
    auto-format = false;
  }];
  programs.helix.languages.language-server.markdown-oxide = {
    command = "markdown-oxide";
  };
  home.packages = with pkgs; [ markdown-oxide dprint ];
}
