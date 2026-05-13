{config, ...}: {
  config.flake.lib.dev.langs."c-based" = {
    helix = config.flake.lib.helix.mkLangs [
      {
        name = "c";
        scope = "source.c";
        file-types = ["c" "h"];
        comment-token = "//";
        block-comment-tokens = {
          start = "/*";
          end = "*/";
        };
        lsp = "clangd";
        formatter = "clang-format";
      }
      {
        name = "cpp";
        scope = "source.cpp";
        file-types = ["cpp" "hpp" "cxx" "hxx" "cc" "hh"];
        comment-token = "//";
        block-comment-tokens = {
          start = "/*";
          end = "*/";
        };
        lsp = "clangd";
        formatter = "clang-format";
      }
    ];
    extraPackages = pkgs: [pkgs.clang-tools];
  };
}
