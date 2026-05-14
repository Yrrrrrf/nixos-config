# src/home/packages/dev/lang/nu.nix
{config, ...}: {
  config.flake.lib.dev.langs.nu = {
    helix = config.flake.lib.helix.mkLangs {
      name = "nu";
      scope = "source.nu";
      file-types = ["nu"];
      shebangs = ["nu"];
      comment-token = "#";
      lsp = {
        name = "nu-lsp";
        command = "nu";
        args = ["--lsp"];
      };
      formatter = {
        command = "nufmt";
        args = ["--stdin"];
      };
    };
    extraPackages = pkgs:
      with pkgs; [
        nushell
        nufmt # The Rust-based formatter for Nu
      ];
  };
}
