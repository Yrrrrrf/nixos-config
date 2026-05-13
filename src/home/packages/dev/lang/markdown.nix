{config, ...}: {
  config.flake.lib.dev.langs.markdown = {
    helix = config.flake.lib.helix.mkLangs {
      name = "markdown";
      scope = "source.markdown";
      file-types = ["md"];
      lsp = "markdown-oxide";
      formatter = {
        command = "dprint";
        args = ["fmt" "--stdin" "md"];
      };
    };
    extraPackages = pkgs: with pkgs; [markdown-oxide dprint];
  };
}
