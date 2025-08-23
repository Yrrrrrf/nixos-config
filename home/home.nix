# /etc/nixos/home/home.nix
#
# Main Home Manager configuration for the user 'yrrrrrf'.
# This file orchestrates the user's entire environment by importing modules
# and package lists, and setting program configurations.

{ config, pkgs, lib, ... }:

let
  user = import ../user.nix;

  allPkgs = import ./packages.nix { inherit pkgs; };

  # vscode-insiders = import ./vscode-insiders.nix { inherit pkgs lib; };
  vscode-insiders = (pkgs.vscode.override { isInsiders = true; }).overrideAttrs (oldAttrs: rec {
    # We use fetchTarball as shown in the wiki. It requires a different hash format.
    src = (builtins.fetchTarball {
      url = "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
      # We use a placeholder again. The build will fail and give us the correct hash.
      # This hash format (nix-base32) is different from the one we got before.
      sha256 = "12jqmxah7bsg6hfa30dbdgprjqv20yhsbac97wqs58sl2hj88n3m";
    });
    version = "latest"; # The version is dynamic, so we just label it latest.
  });

  # --- Define a list of packages to build a persistent dev environment ---
  # These packages have their libraries (.so) and build files (.pc) made available.
  devInputs = with pkgs; [
    # --- Build-time dependencies ---
    systemd.dev # Provides libudev.pc for Rust build errors
    pkg-config  # Tool to find compiler/linker flags for libraries

    # --- Runtime linking for GUI/Game development ---
    alsa-lib        # Audio libraries (required by SDL_mixer)
    glib            # Core application building blocks (threads, data structures)
    libglvnd        # The GL Vendor-Neutral Dispatch library for OpenGL
    libxkbcommon    # Keyboard handling library for Wayland

    # SDL2 Suite for multimedia and game development
    SDL2
    SDL2_gfx
    SDL2_image
    SDL2_mixer
    SDL2_ttf

    # Core Wayland and X11 libraries
    wayland         # Wayland compositor protocol libraries
    xorg.libX11       # Base X11 client library (for XWayland)
    xorg.libXcursor   # X cursor management library
    xorg.libXi        # X Input extension library
    xorg.libXinerama  # Xinerama multi-monitor extension library
    xorg.libXrandr    # X Resize, Rotate and Reflect extension library

    # Font and Image libraries
    fontconfig      # Library for configuring and customizing font access
    freetype        # A software font engine
    qt6.qtbase      # Qt6 core libraries
    qt6.qtwayland   # Qt6 Wayland integration
    libjpeg
    libpng
    giflib
  ];
in
{
  # --- Module Imports ---
  imports = [
    ../modules/desktop/waybar.nix
    ../modules/desktop/rofi.nix
    ../modules/desktop/dunst.nix
    ../modules/hyprland/hyprland.nix
    ../modules/hyprland/hyprlock.nix
    ../modules/hyprland/hypridle.nix
    ../modules/editor/helix.nix
  ];

  # --- Basic Home Manager Settings ---
  home.username = user.username;
  home.homeDirectory = user.homeDirectory;
  home.stateVersion = "25.05";

  # --- Session Variables & Path ---
  home.sessionVariables = {
    UV_PYTHON_DOWNLOADS = "never";
    LD_LIBRARY_PATH = lib.makeLibraryPath devInputs;
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" devInputs;
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

  # --- User-specific Packages ---
  home.packages =
    allPkgs.guiLibs ++
    allPkgs.systemTools ++
    allPkgs.desktopUtils ++
    allPkgs.cliReplacements ++
    allPkgs.devTools ++
    allPkgs.devIDEs ++
    allPkgs.guiApps ++
    allPkgs.buildTools ++

    [ vscode-insiders ]

    ;

  services.gnome-keyring.enable = true;

  # --- Program Configurations ---
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      # replace commands
      ls = "eza --icons";
      cat = "bat";
      find = "fd";
      grep = "rg";
      y = "yazi";

      lg = "lazygit";
      ld = "lazydocker";

      # window manager shortcuts
      uwsm-init = "uwsm start select";
      hypr-init = "Hyprland -c /etc/nixos/modules/hyprland/hyprland.conf";
      #hypr-init = "dbus-run-session Hyprland -c /etc/nixos/modules/hyprland/hyprland.conf";
    };

    initContent =
      let
        scriptsDir = ../scripts;
      in
      ''
        source ${scriptsDir}/fn.sh
      '';
  };

  programs.atuin.enable = true;
  programs.zoxide.enable = true;
  programs.starship.enable = true;

  programs.git = {
    enable = true;
    userName = user.fullName;
    userEmail = user.email;

    extraConfig = {
      # credential.helper = "${pkgs.git.override { withLibsecret = true; }}/bin/git-credential-libsecret";
      init.defaultBranch = "main";
    };
    
  };

  programs.wezterm = {
    enable = true;
    # This embeds the Lua configuration directly into our Nix file.
    extraConfig = ''
      -- Pull in the wezterm API
      local wezterm = require 'wezterm'
      local config = {}

      -- Use the MONO variant of the Nerd Font for perfect alignment
      config.font = wezterm.font("JetBrainsMono Nerd Font Mono")

      -- Here you can add any other Wezterm settings you like in the future.
      -- For example, to set the color scheme:
      -- config.color_scheme = 'Catppuccin Mocha'

      return config
    '';
  };

  # --- Declarative .desktop files for Native Wayland ---
  xdg.desktopEntries = {
    "obsidian" = {
      name = "Obsidian (Wayland)";
      exec = "obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
      terminal = false;
      type = "Application";
    };
  };

  # --- Declarative Configuration Files ---
  xdg.configFile = {
    "yazi/yazi.toml".text = ''
      [mgr]
      show_hidden = true
      [opener]
      edit = [ { run = 'hx "$@"', block = true } ]
      [open]
      rules = [
        { mime = "text/*", use = "edit" },
        { mime = "inode/x-empty", use = "edit" },
      ]
    '';

  };

  # --- Custom scripts ---
  home.file = {
    # Deploy keyboard shortcut helper scripts
    ".local/bin/kbd-performance" = {
      executable = true;
      source = ../scripts/kbd-performance.sh;
    };

    ".local/bin/kbd-layout" = {
      executable = true;
      source = ../scripts/kbd-layout.sh;
    };

    ".local/bin/kbd-mic" = {
      executable = true;
      source = ../scripts/kbd-mic.sh;
    };

    ".local/bin/kbd-backlight" = {
      executable = true;
      source = ../scripts/kbd-backlight.sh;
    };

    # here add some new scripts...
  };

}
