{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "shell";
  language = {
    name = "bash";
    scope = "source.bash";
    file-types = [
      "sh"
      "bash"
      "zsh"
    ];
    shebangs = [
      "sh"
      "bash"
      "dash"
      "zsh"
    ];
    comment-token = "#";
    language-servers = ["bash-language-server"];
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    formatter = {
      command = "shfmt";
    };
    auto-format = false;
  };
  servers.bash-language-server = {
    command = "bash-language-server";
    args = ["start"];
  };
  extraPackages = pkgs:
    with pkgs; [
      bash-language-server
      shfmt
    ];
}
