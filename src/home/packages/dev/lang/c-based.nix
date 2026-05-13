{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "c-based";
  language = [
    {
      name = "c";
      scope = "source.c";
      file-types = ["c" "h"];
      language-servers = ["clangd"];
      comment-token = "//";
      block-comment-tokens = {
        start = "/*";
        end = "*/";
      };
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      formatter = {command = "clang-format";};
      auto-format = false;
    }
    {
      name = "cpp";
      scope = "source.cpp";
      file-types = ["cpp" "hpp" "cxx" "hxx" "cc" "hh"];
      language-servers = ["clangd"];
      comment-token = "//";
      block-comment-tokens = {
        start = "/*";
        end = "*/";
      };
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      formatter = {command = "clang-format";};
      auto-format = false;
    }
  ];
  servers.clangd.command = "clangd";
  extraPackages = pkgs: [pkgs.clang-tools];
}
