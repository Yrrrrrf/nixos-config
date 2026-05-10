{...}: {
  flake.homeModules.scripts =
    # /etc/nixos/home/modules/scripts.nix
    # Symlinks all custom shell scripts into ~/.local/bin to make them executable.
    {pkgs, ...}: {
      home.file = {
        # Keyboard Shortcut scripts
        ".local/bin/kbd-performance" = {
          executable = true;
          source = ../../scripts/kbd-performance.sh; # Note the updated relative path
        };
        ".local/bin/kbd-layout" = {
          executable = true;
          source = ../../scripts/kbd-layout.sh;
        };
        ".local/bin/kbd-mic" = {
          executable = true;
          source = ../../scripts/kbd-mic.sh;
        };
        ".local/bin/volume" = {
          executable = true;
          source = ../../scripts/kbd-volume.sh;
        };
        ".local/bin/kbd-backlight" = {
          executable = true;
          source = ../../scripts/kbd-backlight.sh;
        };

        # Screenshot scripts
        ".local/bin/screenshot" = {
          executable = true;
          source = ../../scripts/screenshot.sh;
        };
      };
    };
}
