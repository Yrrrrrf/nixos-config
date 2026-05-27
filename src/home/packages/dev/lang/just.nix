{config, ...}: {
  config.flake.lib.dev.langs.just = {
    helix = config.flake.lib.helix.mkLangs {
      name = "just";
      scope = "source.just";
      file-types = [
        "just"
        {glob = "Justfile";}
        {glob = "justfile";}
      ];
      comment-token = "#";
      lsp = "just-lsp";
      formatter = {
        command = "just";
        args = ["--dump" "--unstable" "--justfile" "-"];
      };
    };
    extraPackages = pkgs: with pkgs; [just-lsp just];
  };
}
