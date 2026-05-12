{inputs, ...}: {
  flake.homeModules.desktop = {
    config,
    pkgs,
    lib,
    theme,
    ...
  }: let
  in {
    imports = [
      inputs.self.homeModules.stylix
    ];

    # Enable only non-conflicting programs/services
    # Native configs are written via home.file
    services.swayosd.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = theme.apply (builtins.readFile ./hyprland.conf);
    };

    home.file = {
      ".config/hypr/hyprlock.conf".text = theme.apply (builtins.readFile ./hyprlock.conf);
      ".config/hypr/hypridle.conf".text = builtins.readFile ./hypridle.conf;
      ".config/waybar/config.jsonc".text = builtins.readFile ./waybar.jsonc;
      ".config/waybar/style.css".text = theme.apply (builtins.readFile ./waybar-style.css);
      ".config/rofi/config.rasi".text = lib.mkForce (theme.apply (builtins.readFile ./rofi.rasi));
      ".config/dunst/dunstrc".text = lib.mkForce (theme.apply (builtins.readFile ./dunst.conf));
      ".config/wezterm/wezterm.lua".text = builtins.readFile ./wezterm.lua;
      ".config/swayosd/style.css".text = theme.apply (builtins.readFile ./swayosd-style.css);

      ".local/bin/waybar-powermenu" = {
        source = ./scripts/powermenu.nu;
        executable = true;
      };

      ".local/bin/kbd-backlight" = {
        source = ./scripts/kbd-backlight.nu;
        executable = true;
      };
      ".local/bin/kbd-layout" = {
        source = ./scripts/kbd-layout.nu;
        executable = true;
      };
      ".local/bin/kbd-mic" = {
        source = ./scripts/kbd-mic.nu;
        executable = true;
      };
      ".local/bin/kbd-performance" = {
        source = ./scripts/kbd-performance.nu;
        executable = true;
      };
      ".local/bin/screenshot" = {
        source = ./scripts/screenshot.nu;
        executable = true;
      };
    };

    home.packages = with pkgs; [
      playerctl # Media player control
      cliphist # Clipboard history manager
      wl-clipboard # Wayland clipboard utilities
      swww # Wallpaper daemon
      pavucontrol # PulseAudio volume control
      brightnessctl # Backlight control
      libnotify # Notification library (notify-send)
      xfce.thunar # File manager
      swayosd # On-screen display for volume/brightness
      rofi # Application launcher
      waybar # Status bar
      wezterm # Terminal emulator
      hypridle # Idle daemon
      hyprlock # Screen locker
      dunst # Notification daemon
      hyprshot # Screenshot tool
    ];
  };
}
