{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "yaml";
  language = {
    name = "yaml";
    scope = "source.yaml";
    file-types = ["yml" "yaml"];
    comment-token = "#";
    language-servers = ["yaml-language-server"];
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    formatter = {
      command = "prettier";
      args = ["--parser" "yaml"];
    };
    auto-format = false;
  };
  servers.yaml-language-server = {
    command = "yaml-language-server";
    args = ["--stdio"];
  };
  extraPackages = pkgs:
    with pkgs; [
      yaml-language-server
      nodePackages.prettier
    ];
}
