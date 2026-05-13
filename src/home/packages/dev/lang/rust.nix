{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "rust";
  language = {
    name = "rust";
    scope = "source.rust";
    injection-regex = "rs|rust";
    file-types = ["rs"];
    roots = [
      "Cargo.toml"
      "Cargo.lock"
    ];
    auto-format = false;
    comment-tokens = [
      "//"
      "///"
      "//!"
    ];
    language-servers = ["rust-analyzer"];
    indent = {
      tab-width = 4;
      unit = "    ";
    };
    formatter = {
      command = "rustfmt";
    };
  };
  servers.rust-analyzer.command = "rust-analyzer";
  extraPackages = pkgs:
    with pkgs; [
      (lib.hiPrio rust-analyzer)
      (lib.hiPrio rustfmt)
      rustup
    ];
}
