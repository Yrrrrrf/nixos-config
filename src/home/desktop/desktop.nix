{inputs, ...}: {
  flake.homeModules.desktop = {
    config,
    pkgs,
    lib,
    theme,
    ...
  }: let
    # Helper to inject theme colors into strings
    stripHash = color: builtins.substring 1 (builtins.stringLength color) color;

    # Placeholders to replace
    placeholders = {
      "@base@" = theme.base;
      "@mantle@" = theme.mantle;
      "@crust@" = theme.crust;
      "@text@" = theme.text;
      "@mauve@" = theme.mauve;
      "@blue@" = theme.blue;
      "@surface0@" = theme.surface0;
      "@surface1@" = theme.surface1;
      "@overlay0@" = theme.overlay0;
      "@green@" = theme.green;
      "@yellow@" = theme.yellow;
      "@red@" = theme.red;
      "@peach@" = theme.peach;
      "@teal@" = theme.teal;

      # Raw hex for Hyprland
      "@mauve_raw@" = stripHash theme.mauve;
      "@blue_raw@" = stripHash theme.blue;
      "@surface0_raw@" = stripHash theme.surface0;
      "@crust_raw@" = stripHash theme.crust;
      "@text_raw@" = stripHash theme.text;
      "@mantle_raw@" = stripHash theme.mantle;

      "@borderRadius_island@" = toString theme.style.borderRadius.island;
      "@borderRadius_pill@" = toString theme.style.borderRadius.pill;
      "@borderWidth@" = toString theme.style.borderWidth;
      "@wallpaper@" = toString ./wallpaper.png;
    };

    applyTheme = text:
      builtins.replaceStrings (builtins.attrNames placeholders) (builtins.attrValues placeholders) text;
  in {
    imports = [
      inputs.stylix.homeModules.stylix
      inputs.self.homeModules.theme
    ];

    # Enable all programs/services
    services.hypridle.enable = true;
    # programs.hyprlock.enable = true;
    # services.dunst.enable = true;
    programs.waybar.enable = true;
    # programs.rofi.enable = true;
    programs.wezterm.enable = true;
    services.swayosd.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = applyTheme (builtins.readFile ./hyprland.conf);
    };

    home.file = {
      ".config/hypr/hyprlock.conf".text = applyTheme (builtins.readFile ./hyprlock.conf);
      ".config/hypr/hypridle.conf".text = builtins.readFile ./hypridle.conf;
      ".config/waybar/config.jsonc".text = builtins.readFile ./waybar.jsonc;
      ".config/waybar/style.css".text = applyTheme (builtins.readFile ./waybar-style.css);
      ".config/rofi/config.rasi".text = lib.mkForce (applyTheme (builtins.readFile ./rofi.rasi));
      ".config/dunst/dunstrc".text = lib.mkForce (applyTheme (builtins.readFile ./dunst.conf));
      ".wezterm.lua".text = builtins.readFile ./wezterm.lua;

      ".local/bin/waybar-powermenu" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          case $1 in
              "Logout") hyprctl dispatch exit ;;
              "Suspend") systemctl suspend ;;
              "Reboot") systemctl reboot ;;
              "Shutdown") systemctl poweroff ;;
          esac
        '';
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
      ".local/bin/volume" = {
        source = ./scripts/volume.nu;
        executable = true;
      };
    };

    home.packages = with pkgs; [
      playerctl
      cliphist
      wl-clipboard
      swww
      pavucontrol
      brightnessctl
      libnotify
      xfce.thunar
      swayosd
    ];

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      image = ./wallpaper.png;
      polarity = "dark";
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        sizes = {
          applications = 12;
          terminal = 12;
          desktop = 10;
          popups = 10;
        };
      };

      targets = {
        dunst.enable = lib.mkForce false;
        hyprlock.enable = lib.mkForce false;
        rofi.enable = lib.mkForce false;
        waybar.enable = lib.mkForce false;
        hyprland.enable = lib.mkForce false;
      };
      autoEnable = false;
      # Re-enable standard things we want themed
      targets.gtk.enable = true;
      targets.qt.enable = true;
      targets.wezterm.enable = true; # Let Stylix theme the terminal base colors
      targets.fish.enable = true;
      targets.bat.enable = true;
      targets.btop.enable = true;
    };

    systemd.user.services.swayosd-server = {
      Unit = {
        Description = "SwayOSD Service";
        Documentation = "https://github.com/ErikReider/SwayOSD";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
        Restart = "always";
      };
      Install = {WantedBy = ["graphical-session.target"];};
    };

    xdg.configFile."swayosd/style.css".text = applyTheme ''
      window {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 24px;
          font-weight: bold;
          color: @text@;
          background: @base@;
          border: @borderWidth@px solid @mauve@;
          border-radius: @borderRadius_island@px;
          padding: 10px 20px;
      }
      trough {
          background-color: @surface0@;
          border-radius: @borderRadius_pill@px;
          min-height: 10px;
          min-width: 250px;
      }
      progress {
          background-color: @mauve@;
          border-radius: @borderRadius_pill@px;
          min-height: 10px;
      }
      window#input-volume { padding: 10px; }
      window#input-volume trough,
      window#input-volume progress {
          min-height: 0; min-width: 0; margin: 0; padding: 0;
          background-color: transparent; box-shadow: none; border: none;
      }
      window#input-volume image { margin: 0; padding: 5px; color: @mauve@; }
      window#input-volume image:disabled { color: @red@; }
    '';
  };
}
