# /etc/nixos/home/profiles/default.nix
# This file contains the BASE configuration shared by ALL user profiles.
# It should not contain any package lists or profile-specific settings.
{...}: {
  flake.homeModules.default = {
    pkgs,
    config,
    lib,
    inputs,
    ...
  }: let
    user = inputs.self.lib.users.yrrrrrf;
  in {
    # --- Basic Home Manager Settings ---
    home.username = user.username;
    home.homeDirectory = user.homeDirectory;
    home.stateVersion = "25.11";
    home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

    # --- Program Configurations that use User Data ---
    programs.git = {
      enable = true;
      settings = {
        user.name = user.fullName;
        user.email = user.email;
        init.defaultBranch = "main";
      };
    };

    /*
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    */

    # --- FEATURE MODULE IMPORTS ---
    # These are the core modules for the desktop experience.
    imports = [
      inputs.self.homeModules.dunst
      inputs.self.homeModules.hypridle
      inputs.self.homeModules.hyprland
      inputs.self.homeModules.hyprlock
      inputs.self.homeModules.rofi
      inputs.self.homeModules.waybar
      inputs.self.homeModules.wezterm
      inputs.self.homeModules.swayosd
      inputs.self.homeModules.zsh
      inputs.self.homeModules.fastfetch
      inputs.self.homeModules.yazi
      inputs.self.homeModules.helix
      inputs.self.homeModules.scripts
      inputs.self.homeModules.direnv
      inputs.self.homeModules.nix-index
      inputs.self.homeModules.difftastic
      inputs.self.homeModules.agenix
    ];

    # Enable core graphical services needed for everything to work.
    services.dunst.enable = true;
    programs.rofi.enable = true;

    # --- Declarative .desktop files ---
    xdg.desktopEntries = {
      "brave-browser" = {
        name = "Brave Web Browser";
        genericName = "Web Browser";
        # Adding the Overscroll and Wayland flags here:
        exec = "brave --enable-features=TouchpadOverscrollHistoryNavigation --ozone-platform-hint=auto %U";
        terminal = false;
        type = "Application";
        icon = "brave-browser";
        categories = [
          "Network"
          "WebBrowser"
        ];
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
