{ pkgs, ... }:
{
  # Ghostty config
  xdg.configFile."ghostty/config".text = ''
    theme = catppuccin-mocha
    font-family = "JetBrainsMono Nerd Font Mono"
    font-size = 10
    
    # Omarchy-style window padding
    window-padding-x = 14
    window-padding-y = 14
    
    # Remove window decorations (Hyprland handles this)
    window-decoration = false
    
    # Transparency
    background-opacity = 0.95
    
    # Cursor
    cursor-style = block
    cursor-style-blink = false
  '';
}
