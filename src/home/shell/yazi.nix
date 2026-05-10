{...}: {
  flake.homeModules.yazi =
    # /etc/nixos/home/modules/shell/yazi.nix
    # Declarative configuration for the Yazi terminal file manager.
    {pkgs, ...}: {
      # This option declaratively creates ~/.config/yazi/yazi.toml
      xdg.configFile."yazi/yazi.toml".text = ''
        [mgr]
        show_hidden = true
        [opener]
        edit = [ { run = 'hx "$@"', block = true } ]
        [open]
        rules = [
          { mime = "text/*", use = "edit" },
          { mime = "inode/x-empty", use = "edit" },
        ]
      '';
      programs.zsh.shellAliases.y = "yazi";
    };
}
