{config, ...}: {
  config.flake.lib.dev.langs.yaml = {
    helix = config.flake.lib.helix.mkLangs {
      name = "yaml";
      scope = "source.yaml";
      file-types = ["yml" "yaml"];
      comment-token = "#";
      auto-format = false;
      lsp = {
        name = "yaml-language-server";
        args = ["--stdio"];
      };
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "prettier";
        args = ["--parser" "yaml"];
      };
    };
    extraPackages = pkgs: with pkgs; [yaml-language-server nodePackages.prettier];
  };
}
