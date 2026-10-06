{config, ...}: {
  config.flake.lib.dev.langs.hurl = {
    helix = config.flake.lib.helix.mkLangs {
      name = "hurl";
      scope = "source.hurl";
      file-types = ["hurl"];
      formatter = "hurlfmt";
    };
    extraPackages = pkgs:
      with pkgs; [
        hurl
      ];
  };
}
