{inputs, ...}: {
  flake.homeModules.stylix = {
    pkgs,
    config,
    user,
    ...
  }: let
    # Stylix exposes the loaded base16 palette in two forms:
    #   c.*  — raw hex without #  (for Hyprland rgb()/rgba())
    #   h.*  — hex with #         (for CSS, most config formats)
    c = config.lib.stylix.colors;
    h = config.lib.stylix.colors.withHashtag;

    placeholders = {
      # Backgrounds
      "@bg@" = h.base00;
      "@bg-alt@" = h.base01;
      "@surface@" = h.base02;
      "@border@" = h.base03;
      "@subtext@" = h.base04;

      # Text & accents
      "@text@" = h.base05;
      "@accent-alt@" = h.base0D;
      "@accent@" = h.base0E;

      # Status
      "@err@" = h.base08;
      "@extra@" = h.base09;
      "@warn@" = h.base0A;
      "@ok@" = h.base0B;
      "@info@" = h.base0C;

      # Raw (no #) — Hyprland rgb()/rgba() syntax
      "@bg_nohash@" = c.base00;
      "@bg-alt_nohash@" = c.base01;
      "@surface_nohash@" = c.base02;
      "@text_nohash@" = c.base05;
      "@accent-alt_nohash@" = c.base0D;
      "@accent_nohash@" = c.base0E;

      # Layout constants
      "@borderRadius_island@" = toString 12;
      "@borderRadius_pill@" = toString 10;
      "@borderWidth@" = toString 1;
      "@opacity@" = toString 0.95;

      # User assets
      "@wallpaper@" = "${user.wallpaper}";
      "@profileImg@" = "${user.profileImage}";
      "@user@" = user.username;

      # Font — single source of truth via stylix.fonts.monospace.name
      "@monospace@" = config.stylix.fonts.monospace.name;
    };
  in {
    imports = [inputs.stylix.homeModules.stylix];

    _module.args.theme = {
      apply = text:
        builtins.replaceStrings (builtins.attrNames placeholders) (builtins.attrValues placeholders) text;
    };

    stylix = {
      enable = true;
      enableReleaseChecks = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      image = user.wallpaper;
      polarity = "dark";
      opacity.terminal = 0.95;

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.fira-code;
          name = "FiraCode Nerd Font Mono";
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
          applications = 14;
          terminal = 14;
          desktop = 10;
          popups = 10;
        };
      };

      autoEnable = false;
      targets = {
        gtk.enable = true;
        qt.enable = true;
        helix.enable = true;
        yazi.enable = true;
        wezterm.enable = true;
      };
    };
  };
}
