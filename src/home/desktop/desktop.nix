{inputs, ...}: {
  flake.homeModules.desktop = {
    pkgs,
    lib,
    theme,
    user,
    ...
  }: let
    # Auto-discover every .nu file in ./scripts/. Host-specific scripts
    # (e.g. ASUS keyboard backlight) are installed by the host's homeExtras
    # (see src/host/g14/g14.nix).
    #
    # Convention: filenames starting with `_` are libraries — kept with the
    # .nu suffix, not executable (e.g. `_shared.nu`, consumed via
    # `use _shared.nu *`). Every other *.nu is a command: suffix stripped,
    # executable, dropped into ~/.local/bin/.
    scriptFiles = lib.mapAttrs' (
      fname: _type: let
        isLib = lib.hasPrefix "_" fname;
        installName =
          if isLib
          then fname
          else lib.removeSuffix ".nu" fname;
      in
        lib.nameValuePair ".local/bin/${installName}" {
          source = ./scripts + "/${fname}";
          executable = !isLib;
        }
    ) (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nu" n) (builtins.readDir ./scripts));
  in {
    imports = [
      inputs.self.homeModules.stylix
      inputs.walker.homeManagerModules.default
    ];

    services.swayosd.enable = true;

    wayland.windowManager.hyprland = {
      enable = true;
      extraConfig = theme.apply (builtins.readFile ./hyprland.lua);
    };

    home.file =
      scriptFiles
      // {
        ".config/hypr/hyprlock.conf".text = theme.apply (builtins.readFile ./hyprlock.conf);
        ".config/hypr/hypridle.conf".text = builtins.readFile ./hypridle.conf;
        ".config/waybar/config.jsonc".text = theme.apply (builtins.readFile ./waybar.jsonc);
        ".config/waybar/style.css".text = theme.apply (builtins.readFile ./waybar-style.css);
        ".config/dunst/dunstrc".text = lib.mkForce (theme.apply (builtins.readFile ./dunst.conf));
        ".config/swayosd/style.css".text = theme.apply (builtins.readFile ./swayosd-style.css);
      };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = "com.system76.CosmicFiles.desktop";
        "application/x-gnome-saved-search" = "com.system76.CosmicFiles.desktop";
        "x-scheme-handler/file" = "com.system76.CosmicFiles.desktop";
      };
    };

    home.packages = with pkgs; [
      playerctl
      cliphist
      wl-clipboard
      awww
      pavucontrol
      brightnessctl
      libnotify
      cosmic-files
      swayosd
      waybar
      hypridle
      hyprlock
      dunst
      hyprshot
    ];
    programs.walker = {
      enable = true;
      runAsService = true;
      config = {
        theme = user.username;
        builtins = {
          applications.weight = 5;
          runner.weight = 1;
          symbols.weight = 1;
          calc.weight = 1;
        };
      };
      themes.${user.username}.style = theme.apply (builtins.readFile ./walker-style.css);
    };
    programs.wezterm = {
      enable = true;
      extraConfig = ''
        config.hide_tab_bar_if_only_one_tab = true
        config.scrollback_lines = 10000
      '';
    };
  };
}
