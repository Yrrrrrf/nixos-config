{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "nix";
  language = {
    name = "nix";
    scope = "source.nix";
    file-types = ["nix"];
    comment-token = "#";
    language-servers = ["nil"];
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    formatter = {command = "alejandra";};
    auto-format = false;
  };
  servers.nil.command = "nil";
  extraPackages = pkgs: with pkgs; [nil alejandra];
}
