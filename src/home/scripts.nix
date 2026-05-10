{...}: {
  flake.homeModules.scripts =
    # /etc/nixos/home/modules/scripts.nix
    # Symlinks all custom shell scripts into ~/.local/bin to make them executable.
    {pkgs, ...}: {
      home.file = {
        # Keyboard Shortcut scripts
        ".local/bin/kbd-performance" = {
          executable = true;
          source = ../../home/scripts/kbd-performance.sh; # Note the updated relative path
        };
        ".local/bin/kbd-layout" = {
          executable = true;
          source = ../../home/scripts/kbd-layout.sh;
        };
        ".local/bin/kbd-mic" = {
          executable = true;
          source = ../../home/scripts/kbd-mic.sh;
        };
        ".local/bin/volume" = {
          executable = true;
          source = ../../home/scripts/kbd-volume.sh;
        };
        ".local/bin/kbd-backlight" = {
          executable = true;
          source = ../../home/scripts/kbd-backlight.sh;
        };

        # Screenshot scripts
        ".local/bin/screenshot" = {
          executable = true;
          source = ../../home/scripts/screenshot.sh;
        };
      };
    };
}
