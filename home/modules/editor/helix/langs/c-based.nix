{ pkgs, ... }:
{
  programs.helix.languages.language = [
    {
      name = "c";
      scope = "source.c";
      file-types = ["c" "h"];
      language-servers = [ "clangd" ];
      comment-token = "//";
      block-comment-tokens = { start = "/*"; end = "*/"; };
      indent = { tab-width = 4; unit = "    "; };
      formatter = { command = "clang-format"; };
      auto-format = false;
    }
    {
      name = "cpp";
      scope = "source.cpp";
      file-types = ["cpp" "hpp" "cxx" "hxx" "cc" "hh"];
      language-servers = [ "clangd" ];
      comment-token = "//";
      block-comment-tokens = { start = "/*"; end = "*/"; };
      indent = { tab-width = 4; unit = "    "; };
      formatter = { command = "clang-format"; };
      auto-format = false;
    }
  ];
  programs.helix.languages.language-server.clangd = {
    command = "clangd";
  };
  home.packages = with pkgs; [ clang-tools ];
}
