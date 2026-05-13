{config, ...}: {
  config.flake.lib.dev.langs.toml = {
    helix = config.flake.lib.helix.mkLangs {
      name = "toml";
      scope = "source.toml";
      file-types = ["toml"];
      comment-token = "#";
      lsp = {
        name = "taplo";
        args = ["lsp" "stdio"];
      };
      formatter = {
        command = "taplo";
        args = ["format" "-"];
      };
    };
    extraPackages = pkgs: [pkgs.taplo];
  };
}
