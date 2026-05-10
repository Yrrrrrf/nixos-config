{...}: {
  flake.homeModules.wezterm =
    # /etc/nixos/home/modules/desktop/wezterm.nix
    # Declarative configuration for the Wezterm terminal emulator.
    {pkgs, ...}: {
      programs.wezterm = {
        enable = true;
        # This embeds the Lua configuration directly into our Nix file.
        extraConfig = ''
          -- Pull in the wezterm API
          local wezterm = require 'wezterm'
          local config = {}

          -- Use the MONO variant of the Nerd Font for perfect alignment
          config.font = wezterm.font("JetBrainsMono Nerd Font Mono")
          -- config.font = wezterm.font("FiraCode Nerd Font")

          -- Here you can add any other Wezterm settings you like in the future.
          -- For example, to set the color scheme:
          config.window_background_opacity = 0.95

          return config
        '';
      };
    };
}
