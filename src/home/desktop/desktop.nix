{inputs, ...}: {
  flake.homeModules.desktop = {
    config,
    pkgs,
    lib,
    theme,
    ...
  }: let
    # Generic, host-agnostic scripts. Installed as ~/.local/bin/<name>.
    # Host-specific scripts (e.g. ASUS keyboard backlight) are installed by
    # the host's homeExtras (see src/host/g14/g14.nix).
    scripts = ["volume" "mic" "layout" "screenshot" "powermenu"];

    scriptFiles = builtins.listToAttrs (map (n: {
        name = ".local/bin/${n}";
        value = {
          source = ./scripts/${n}.nu;
          executable = true;
        };
      })
      scripts);
  in {
    imports = [
      inputs.self.homeModules.stylix
    ];

    services.swayosd.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = theme.apply (builtins.readFile ./hyprland.conf);
    };

    home.file =
      scriptFiles
      // {
        ".config/hypr/hyprlock.conf".text = theme.apply (builtins.readFile ./hyprlock.conf);
        ".config/hypr/hypridle.conf".text = builtins.readFile ./hypridle.conf;
        ".config/waybar/config.jsonc".text = builtins.readFile ./waybar.jsonc;
        ".config/waybar/style.css".text = theme.apply (builtins.readFile ./waybar-style.css);
        ".config/rofi/config.rasi".text = lib.mkForce (theme.apply (builtins.readFile ./rofi.rasi));
        ".config/dunst/dunstrc".text = lib.mkForce (theme.apply (builtins.readFile ./dunst.conf));
        ".config/wezterm/wezterm.lua".text = theme.apply (builtins.readFile ./wezterm.lua);
        ".config/swayosd/style.css".text = theme.apply (builtins.readFile ./swayosd-style.css);
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
      rofi
      waybar
      wezterm
      hypridle
      hyprlock
      dunst
      hyprshot
    ];
  };
}
