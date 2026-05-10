# /etc/nixos/home/profiles/default.nix
# This file contains the BASE configuration shared by ALL user profiles.
# It should not contain any package lists or profile-specific settings.
{
  pkgs,
  config,
  lib,
  ...
}: let
  user = import ../users/yrrrrrf.nix;
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

  # --- FEATURE MODULE IMPORTS ---
  # These are the core modules for the desktop experience.
  imports = [
    ../modules/desktop/default.nix
    ../modules/shell/zsh.nix
    ../modules/editor/helix/default.nix
    ../modules/shell/yazi.nix
    ../modules/shell/tools/default.nix
    ../modules/scripts.nix
  ];

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
}
