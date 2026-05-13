{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "asm";
  language = [
    {
      name = "gas";
      scope = "source.asm";
      file-types = ["asm" "s"];
      comment-token = ";";
      language-servers = ["asm-lsp"];
      auto-format = false;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
    }
    {
      name = "nasm";
      scope = "source.asm";
      file-types = ["asm" "s"];
      comment-token = ";";
      language-servers = ["asm-lsp"];
      auto-format = false;
      indent = {
        tab-width = 4;
        unit = "    ";
      };
    }
  ];
  servers.asm-lsp.command = "asm-lsp";
  extraPackages = pkgs: [pkgs.asm-lsp];
}
