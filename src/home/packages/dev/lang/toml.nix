{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "toml";
  language = {
    name = "toml";
    scope = "source.toml";
    file-types = ["toml"];
    comment-token = "#";
    language-servers = ["taplo"];
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    formatter = {
      command = "taplo";
      args = ["format" "-"];
    };
    auto-format = false;
  };
  servers.taplo = {
    command = "taplo";
    args = ["lsp" "stdio"];
  };
  extraPackages = pkgs: [pkgs.taplo];
}
