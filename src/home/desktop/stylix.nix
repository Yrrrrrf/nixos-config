{inputs, ...}: {
  flake.homeModules.stylix = {
    lib,
    pkgs,
    ...
  }: let
    colors = {
      rosewater = "#f5e0dc";
      flamingo = "#f2cdcd";
      pink = "#f5c2e7";
      mauve = "#cba6f7";
      red = "#f38ba8";
      maroon = "#eba0ac";
      peach = "#fab387";
      yellow = "#f9e2af";
      green = "#a6e3a1";
      teal = "#94e2d5";
      sky = "#89dceb";
      sapphire = "#74c7ec";
      blue = "#89b4fa";
      lavender = "#b4befe";
      text = "#cdd6f4";
      subtext1 = "#bac2de";
      subtext0 = "#a6adc8";
      overlay2 = "#9399b2";
      overlay1 = "#7f849c";
      overlay0 = "#6c7086";
      surface2 = "#585b70";
      surface1 = "#45475a";
      surface0 = "#313244";
      base = "#1e1e2e";
      mantle = "#181825";
      crust = "#11111b";
    };

    stripHash = color: builtins.substring 1 ((builtins.stringLength color) - 1) color;

    # Map for builtins.replaceStrings
    placeholders = {
      "@base@" = colors.base;
      "@mantle@" = colors.mantle;
      "@crust@" = colors.crust;
      "@text@" = colors.text;
      "@mauve@" = colors.mauve;
      "@blue@" = colors.blue;
      "@surface0@" = colors.surface0;
      "@surface1@" = colors.surface1;
      "@overlay0@" = colors.overlay0;
      "@green@" = colors.green;
      "@yellow@" = colors.yellow;
      "@red@" = colors.red;
      "@peach@" = colors.peach;
      "@teal@" = colors.teal;

      # Raw hex for Hyprland
      "@mauve_raw@" = stripHash colors.mauve;
      "@blue_raw@" = stripHash colors.blue;
      "@surface0_raw@" = stripHash colors.surface0;
      "@crust_raw@" = stripHash colors.crust;
      "@text_raw@" = stripHash colors.text;
      "@mantle_raw@" = stripHash colors.mantle;

      "@borderRadius_island@" = toString 12;
      "@borderRadius_pill@" = toString 10;
      "@borderWidth@" = toString 1;
      "@wallpaper@" = toString ./wallpaper.jpg;
      "@opacity@" = toString 0.95;
      "@monospace@" = "JetBrainsMono Nerd Font Mono";
    };
  in {
    imports = [inputs.stylix.homeModules.stylix];

    _module.args.theme =
      colors
      // {
        apply = text:
          builtins.replaceStrings (builtins.attrNames placeholders) (builtins.attrValues placeholders) text;
        style = {
          borderRadius = {
            island = 12;
            pill = 10;
          };
          borderWidth = 1;
          spacing = 8;
        };
      };

    stylix = {
      enable = true;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      image = ./wallpaper.jpg;
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
        waybar.enable = lib.mkForce false;
        hyprland.enable = lib.mkForce false;
      };
      autoEnable = false;
      # Re-enable standard things we want themed
      targets.gtk.enable = true;
      targets.qt.enable = true;
      targets.wezterm.enable = lib.mkForce false;
      targets.helix.enable = lib.mkForce false;
      targets.yazi.enable = lib.mkForce false;
    };
  };
}
