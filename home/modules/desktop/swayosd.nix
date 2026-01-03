{ pkgs, ... }:
{
  # Enable the daemon
  services.swayosd.enable = true;

  # Style it to match Catppuccin (Ported from Omarchy's CSS)
  xdg.configFile."swayosd/style.css".text = ''
    window {
      border-radius: 20px;
      background-color: rgba(30, 30, 46, 0.95); /* Base */
      border: 2px solid #cba6f7; /* Mauve */
    }
    
    scale {
      background-color: #313244; /* Surface0 */
    }
    
    trough {
      background-color: #313244; /* Surface0 */
      border-radius: 20px;
    }
    
    highlight {
      background-color: #cba6f7; /* Mauve */
      border-radius: 20px;
    }
  '';
}
