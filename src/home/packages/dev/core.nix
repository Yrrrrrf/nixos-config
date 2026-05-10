{lib, ...}: {
  options.flake.lib.pkgsets.dev = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.pkgsets.dev = {
    build = pkgs: with pkgs; [pkg-config gcc openssl.dev];
    ides = pkgs: with pkgs; [vscode jetbrains-toolbox gitkraken unityhub antigravity];
  };
}
