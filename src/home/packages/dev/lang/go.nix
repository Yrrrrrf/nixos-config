{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "go";
  language = {
    name = "go";
    scope = "source.go";
    file-types = ["go"];
    roots = ["go.work" "go.mod"];
    comment-token = "//";
    language-servers = ["gopls"];
    indent = {
      tab-width = 4;
      unit = "\t";
    };
    formatter = {command = "gofmt";};
    auto-format = false;
  };
  servers.gopls.command = "gopls";
  extraPackages = pkgs: with pkgs; [gopls go];
}
