# /etc/nixos/home/packages.nix
#
# This file's sole responsibility is to define and categorize all user-level packages.
# It takes 'pkgs' as an input and returns an attribute set of package lists.
# This approach keeps the main home.nix clean and makes package management modular.

{ pkgs }:

{
  # --- NEW: Core Libraries for GUI & Media Applications ---
  # These provide the essential .so files that graphical applications need to run.
  guiLibs = with pkgs; [
    # For Wayland support (needed by winit)
    wayland
    libxkbcommon
    # For X11/XWayland fallback support (needed by winit, PyQt)
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libXinerama
    # For OpenGL graphics (libGL.so.1 - needed by PyQt, Pygame, winit)
    libglvnd
    libGL
    # For audio and system utilities (needed by Pygame mixer)
    alsa-lib # Provides audio backend libraries

    SDL2
    SDL2_ttf
    SDL2_net
    SDL2_gfx
    SDL2_mixer
    SDL2_sound
    SDL2_image

    glib     # Provides gthread, among other things
  ];

  # --- Core System & Monitoring Tools ---
  # Essential utilities for system monitoring and interaction.
  systemTools = with pkgs; [
    btop        # A resource monitor that shows usage and stats for processes.
    neofetch    # Displays system information in a visually appealing way.
    unimatrix   # A fun, matrix-style screen effect for the terminal.
    brightnessctl # A command-line tool to control screen brightness.
    jq          # A lightweight and flexible command-line JSON processor.
    tree        # A utility to display directory structures in a tree-like format.
  ];

  # --- Desktop Environment & Core Utilities ---
  # The fundamental components of the graphical desktop environment.
  desktopUtils = with pkgs; [
    wezterm     # A powerful, GPU-accelerated terminal emulator.
    swww        # A wallpaper daemon for Wayland, used to set and manage wallpapers.
    hyprlock    # The screen locker for the Hyprland session.
    hypridle    # The idle daemon to trigger events (like locking) on inactivity.
    yazi        # A modern, fast terminal-based file manager.
    xfce.thunar # A traditional, graphical file manager
    dunst       # Notification daemon for displaying alerts.
    libnotify   # Provides the 'notify-send' command used in scripts.


    hyprshot    # A modern screenshot tool designed for Hyprland.
    # flameshot	  # Photo Editor.	Annotates, edits, and saves the final image.
    #(flameshot.override { enableWlrSupport = true; })
    # grim	      # Cameraman. Asks the compositor for a picture of pixels.
    # slurp       #	Frame Selector.	Securely asks the compositor to let you select a region.

    cliphist    # Clipboard history manager.
    wl-clipboard  # Provides wl-copy and wl-paste for Wayland clipboard integration.
    cheese      # camera utils!
  ];

  # --- Modern Command-Line Replacements ---
  # An improved suite of common CLI tools, mostly written in Rust for performance.
  cliReplacements = with pkgs; [
    eza         # A modern replacement for 'ls' with icons and better defaults.
    bat         # A 'cat' clone with syntax highlighting and Git integration.
    fd          # A simple, fast, and user-friendly alternative to 'find'.
    ripgrep     # A line-oriented search tool that recursively searches for a regex pattern.
  ];

  # --- Build Tools & Dependencies ---
  # Essential libraries and tools required for compiling software from source.
  buildTools = with pkgs; [
    pkg-config
    stdenv.cc
    openssl
    systemd
    # autoPatchelfHook # A hook to automatically patch ELF binaries.
  ];

  # --- Development Toolchains & Runtimes ---
  # Compilers, interpreters, and runtimes for various programming languages.
  devTools = with pkgs; [
    uv          # An extremely fast Python package installer and resolver.
    gcc         # The GNU Compiler Collection, essential for C/C++ development.
    rustup      # The official tool to install and manage Rust toolchains.
    nodejs      # JavaScript runtime for server-side development.
    bun         # A fast, all-in-one JavaScript toolkit (runtime, bundler, test runner).
    deno        # A modern and secure runtime for JavaScript and TypeScript.

    lazygit     # A terminal UI for git commands
  ];

  # --- Development IDEs & GUI Tools ---
  # Graphical applications for software development and version control.
  devIDEs = with pkgs; [
    jetbrains.goland # A powerful and ergonomic IDE for Go development.
    jetbrains.datagrip # A multi-database IDE for developers and DBAs.
    gitkraken        # A graphical Git client to visualize and manage repositories.
  ];

  # --- General Purpose GUI Applications ---
  # Everyday graphical applications for entertainment, productivity, and browsing.
  guiApps = with pkgs; [
    spotify     # Music streaming service client.
    obsidian    # A powerful knowledge base and note-taking app.
    steam       # The leading digital distribution platform for PC gaming.
    firefox     # A free and open-source web browser.
    brave       # A privacy-focused web browser.
    thunderbird # Full-featured e-mail client.
    gimp3       # GNU Image Manipulation Program
    inkscape    # Vector graphics editor
    obs-studio  # Software for video recording and live streaming
    mendeley    # Reference manager and academic social network
    libreoffice-qt6-fresh
    ciscoPacketTracer8
  ];
}
