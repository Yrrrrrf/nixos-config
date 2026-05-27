{config, ...}: {
  config.flake.lib.dev.langs.asm = {
    helix = config.flake.lib.helix.mkLangs [
      {
        name = "gas";
        scope = "source.asm";
        file-types = ["s"];
        comment-token = ";";
        lsp = "asm-lsp";
      }
      {
        name = "nasm";
        scope = "source.asm";
        file-types = ["asm" "nasm"];
        comment-token = ";";
        lsp = "asm-lsp";
      }
    ];
    extraPackages = pkgs: [pkgs.asm-lsp];
  };
}
