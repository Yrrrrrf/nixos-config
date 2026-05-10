{pkgs, ...}: {
  programs.helix.languages.language = [
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
  programs.helix.languages.language-server.asm-lsp = {
    command = "asm-lsp";
  };
  home.packages = with pkgs; [asm-lsp];
}
