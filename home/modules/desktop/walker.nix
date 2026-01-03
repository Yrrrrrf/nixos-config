{ pkgs, ... }:
{
  programs.walker = {
    enable = true;
    runAsService = true;

    # Omarchy-style config
    config = {
      placeholder = "Search...";
      show_initial_entries = true;
      enable_typeahead = true;
      fullscreen = false;
      list = {
        height = 400;
        always_show = true;
      };
      search = {
        placeholder = "Search Applications...";
      };

      # Define a custom "Power" module
      plugins = [
        {
          name = "power";
          placeholder = "Power Menu";
          switcher_only = true; # Only shows when explicitly called
          entries = [
            { label = "Lock"; exec = "hyprlock"; icon = "lock"; }
            { label = "Suspend"; exec = "systemctl suspend"; icon = "sleep"; }
            { label = "Reboot"; exec = "systemctl reboot"; icon = "restart"; }
            { label = "Shutdown"; exec = "systemctl poweroff"; icon = "power"; }
          ];
        }
      ];

    };

    # Stylesheet (Minimal Catppuccin)
    theme = {
      style = ''
        #window {
          background-color: rgba(30, 30, 46, 0.95); /* Base */
          color: #cdd6f4; /* Text */
          border-radius: 12px;
          border: 2px solid #cba6f7; /* Mauve */
        }
        #input {
          background: transparent;
          border-bottom: 1px solid #45475a;
          color: #cdd6f4;
        }
        #list {
          color: #cdd6f4;
        }
        #entry:selected {
          background-color: #cba6f7; /* Mauve */
          color: #1e1e2e; /* Base (Dark text) */
          border-radius: 8px;
        }
      '';
    };
  };
}
