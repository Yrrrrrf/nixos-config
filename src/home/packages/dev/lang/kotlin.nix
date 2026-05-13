{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "kotlin";
  language = {
    name = "kotlin";
    scope = "source.kotlin";
    file-types = ["kt" "kts"];
    comment-token = "//";
    language-servers = ["kotlin-language-server"];
    auto-format = false;
    indent = {
      tab-width = 4;
      unit = "    ";
    };
    formatter = {
      command = "ktlint";
      args = ["--format" "--stdin"];
    };
  };
  servers.kotlin-language-server.command = "kotlin-language-server";
  extraPackages = pkgs: with pkgs; [kotlin-language-server ktlint gradle tomcat openjdk21];
}
