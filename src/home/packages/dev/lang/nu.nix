{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "nu";
  language = {
    name = "nu";
    scope = "source.nu";
    file-types = ["nu"];
    shebangs = ["nu"];
    comment-token = "#";
    language-servers = ["nu-lsp"];
    auto-format = false;
    indent = {
      tab-width = 2;
      unit = "  ";
    };
  };
  servers.nu-lsp = {
    command = "nu";
    args = ["--lsp"];
  };
  extraPackages = pkgs: [pkgs.nushell];
}
