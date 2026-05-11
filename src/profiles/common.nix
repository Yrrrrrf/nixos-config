{inputs, ...}: {
  flake.homeModules.common = {
    pkgs,
    config,
    lib,
    inputs,
    ...
  }: let
    user = inputs.self.lib.users.yrrrrrf;
    cli = inputs.self.lib.pkgsets.cli;
  in {
    home.username = user.username;
    home.homeDirectory = user.homeDirectory;
    home.stateVersion = "25.11";
    home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

    programs.git = {
      enable = true;
      settings = {
        user.name = user.fullName;
        user.email = user.email;
        init.defaultBranch = "main";
      };
    };

    imports = [
      inputs.self.homeModules.dunst
      inputs.self.homeModules.hypridle
      inputs.self.homeModules.hyprland
      inputs.self.homeModules.hyprlock
      inputs.self.homeModules.rofi
      inputs.self.homeModules.waybar
      inputs.self.homeModules.wezterm
      inputs.self.homeModules.swayosd
      inputs.self.homeModules.shell
      inputs.self.homeModules.nushell
      inputs.self.homeModules.zsh
    ];

    home.file = {
      ".local/bin/kbd-performance" = {
        executable = true;
        source = ../home/shell/scripts/kbd-performance.sh;
      };
      ".local/bin/kbd-layout" = {
        executable = true;
        source = ../home/shell/scripts/kbd-layout.sh;
      };
      ".local/bin/kbd-mic" = {
        executable = true;
        source = ../home/shell/scripts/kbd-mic.sh;
      };
      ".local/bin/volume" = {
        executable = true;
        source = ../home/shell/scripts/kbd-volume.sh;
      };
      ".local/bin/kbd-backlight" = {
        executable = true;
        source = ../home/shell/scripts/kbd-backlight.sh;
      };
      ".local/bin/screenshot" = {
        executable = true;
        source = ../home/shell/scripts/screenshot.sh;
      };
    };

    home.packages = cli.core pkgs;

    services.dunst.enable = true;
    programs.rofi.enable = true;

    xdg.desktopEntries = {
      "brave-browser" = {
        name = "Brave Web Browser";
        genericName = "Web Browser";
        exec = "brave --enable-features=TouchpadOverscrollHistoryNavigation --ozone-platform-hint=auto %U";
        terminal = false;
        type = "Application";
        icon = "brave-browser";
        categories = ["Network" "WebBrowser"];
      };
      "obsidian" = {
        name = "Obsidian";
        exec = "obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
        terminal = false;
        type = "Application";
      };
    };
  };
}
