{config, ...}: {
  config.flake.lib.dev.langs.lua = {
    helix = config.flake.lib.helix.mkLangs {
      name = "lua";
      scope = "source.lua";
      file-types = ["lua"];
      comment-token = "--";
      lsp = "lua-language-server";
      formatter = {
        command = "stylua";
        args = ["-"];
      };
    };
    extraPackages = pkgs: with pkgs; [lua-language-server stylua lua];
  };
}
