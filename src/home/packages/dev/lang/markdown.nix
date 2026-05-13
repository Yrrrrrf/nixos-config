{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "markdown";
  language = {
    name = "markdown";
    scope = "source.markdown";
    file-types = ["md"];
    language-servers = ["markdown-oxide"];
    formatter = {
      command = "dprint";
      args = ["fmt" "--stdin" "md"];
    };
    auto-format = false;
  };
  servers.markdown-oxide.command = "markdown-oxide";
  extraPackages = pkgs: with pkgs; [markdown-oxide dprint];
}
