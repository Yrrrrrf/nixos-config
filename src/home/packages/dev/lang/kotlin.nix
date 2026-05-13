{config, ...}: {
  config.flake.lib.dev.langs.kotlin = {
    helix = config.flake.lib.helix.mkLangs {
      name = "kotlin";
      scope = "source.kotlin";
      file-types = ["kt" "kts"];
      comment-token = "//";
      lsp = "kotlin-language-server";
      formatter = {
        command = "ktlint";
        args = ["--format" "--stdin"];
      };
    };
    extraPackages = pkgs: with pkgs; [kotlin-language-server ktlint gradle tomcat openjdk21];
  };
}
