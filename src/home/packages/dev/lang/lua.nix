{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "lua";
  language = {
    name = "lua";
    scope = "source.lua";
    file-types = ["lua"];
    comment-token = "--";
    language-servers = ["lua-language-server"];
    auto-format = true;
    indent = {
      tab-width = 2;
      unit = "  ";
    };
    formatter = {
      command = "stylua";
      args = ["-"];
    };
  };
  servers.lua-language-server.command = "lua-language-server";
  extraPackages = pkgs: with pkgs; [lua-language-server stylua lua];
}
