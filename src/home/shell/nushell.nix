{ ... }:
{
  flake.homeModules.nushell =
    { pkgs, ... }:
    {
      programs.nushell = {
        enable = true;
        # Basic configuration
        configFile.text = ''
          $env.config = {
            show_banner: false,
          }
          source ${./fn.nu}
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
