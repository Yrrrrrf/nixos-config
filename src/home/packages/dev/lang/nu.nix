{config, ...}: {
  config.flake.lib.dev.langs.nu = {
    helix = config.flake.lib.helix.mkLangs {
      name = "nu";
      scope = "source.nu";
      file-types = ["nu"];
      shebangs = ["nu"];
      comment-token = "#";
      # command differs from server name → use attrset form
      lsp = {
        name = "nu-lsp";
        command = "nu";
        args = ["--lsp"];
      };
    };
    extraPackages = pkgs: [pkgs.nushell];
  };
}
