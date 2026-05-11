{...}: {
  flake.homeModules.nushell = {pkgs, ...}: {
    programs.nushell = {
      enable = true;
      # Basic configuration
      configFile.text = ''
        $env.config = {
          show_banner: false,
        }
      '';
      shellAliases = {
        ls = "ls"; # Nushell's ls is already great
        cat = "bat";
        find = "fd";
        grep = "rg";
        lg = "lazygit";
        fzf = "sk";
        y = "yazi";
      };
    };

    # Integrations for Nushell
    programs.atuin.enableNushellIntegration = true;
    programs.zoxide.enableNushellIntegration = true;
    programs.starship.enableNushellIntegration = true;
    programs.direnv.enableNushellIntegration = true;
  };
}
