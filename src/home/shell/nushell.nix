{...}: {
  flake.homeModules.nushell = {...}: {
    programs.nushell = {
      enable = true;
      # Basic configuration
      extraEnv = ''
        $env.PATH = ($env.PATH | split row (char esep) | prepend ($env.HOME | path join ".local/bin") | uniq)
      '';
      extraConfig = ''
        $env.config.show_banner = false
        ${builtins.readFile ./fn.nu}
      '';
      shellAliases = {
        lg = "lazygit";
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
