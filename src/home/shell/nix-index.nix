{...}: {
  flake.homeModules.nix-index = {
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
