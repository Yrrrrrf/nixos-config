{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "just";
  language = {
    name = "just";
    scope = "source.just";
    file-types = ["Justfile" "just"];
    comment-token = "#";
    language-servers = ["just-lsp"];
    indent = {
      tab-width = 4;
      unit = "    ";
    };
    formatter = {
      command = "just";
      args = ["--fmt" "--unstable"];
    };
    auto-format = false;
  };
  servers.just-lsp.command = "just-lsp";
  extraPackages = pkgs: with pkgs; [just-lsp just];
}
