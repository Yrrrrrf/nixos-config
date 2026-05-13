{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "typst";
  language = {
    name = "typst";
    language-servers = ["tinymist"];
    file-types = ["typ"];
    formatter = {
      command = "typstyle";
    };
  };
  servers.tinymist.command = "tinymist";
  extraPackages = pkgs: with pkgs; [
    tinymist
    typstyle
    typst
  ];
}
