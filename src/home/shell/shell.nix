{inputs, ...}: {
  flake.homeModules.shell = {pkgs, ...}: {
    imports = [
      inputs.agenix.homeManagerModules.default
      # Add nu shell module as default shell
      inputs.self.homeModules.nushell
    ];

    programs = {
      # Enable companion tools for the shell
      atuin.enable = true;
      zoxide.enable = true;
      starship.enable = true;

      # Enable common shell tools
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      nix-index.enable = true;

      difftastic = {
        enable = true;
        git.enable = true;
      };

      fastfetch.enable = true;
      helix.enable = true;
      yazi.enable = true;
    };

    # External config files
    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.jsonc;
    xdg.configFile."helix/config.toml".source = ./helix.toml;
    xdg.configFile."yazi/yazi.toml".source = ./yazi.toml;
  };
}
