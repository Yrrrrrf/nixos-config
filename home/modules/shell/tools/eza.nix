{
  pkgs,
  config,
  ...
}: {
  programs.zsh.shellAliases.ls = "eza --icons";
}
