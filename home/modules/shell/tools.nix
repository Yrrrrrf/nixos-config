{ pkgs, config, ... }: {
  programs.zsh.shellAliases = {
    ls = "eza --icons";
    cat = "bat";
    find = "fd";
    grep = "rg";
    lg = "gitui";
    top = "btm";
    htop = "btm";
    fzf = "sk";
  };
}
