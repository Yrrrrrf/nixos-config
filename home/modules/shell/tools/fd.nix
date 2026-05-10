{
  pkgs,
  config,
  ...
}: {
  programs.zsh.shellAliases.find = "fd";
}
