# /etc/nixos/home/modules/shell/zsh.nix
# Configures the Zsh shell and related command-line tools.
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # window manager shortcuts
      # uwsm-init = "uwsm start select";
    };

    initContent = let
      scriptsDir = ../../scripts;
    in ''
      source ${scriptsDir}/fn.sh
    '';
  };

  # Enable companion tools for the shell
  programs.atuin.enable = true;
  programs.zoxide.enable = true;
  programs.starship.enable = true;
}
