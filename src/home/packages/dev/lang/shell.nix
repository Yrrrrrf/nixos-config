{config, ...}: {
  config.flake.lib.dev.langs.shell = {
    helix = config.flake.lib.helix.mkLangs {
      name = "bash";
      scope = "source.bash";
      file-types = ["sh" "bash" "zsh"];
      shebangs = ["sh" "bash" "dash" "zsh"];
      comment-token = "#";
      lsp = {
        name = "bash-language-server";
        args = ["start"];
      };
      formatter = "shfmt";
    };
    extraPackages = pkgs: with pkgs; [bash-language-server shfmt];
  };
}
