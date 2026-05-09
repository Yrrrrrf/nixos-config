# /etc/nixos/home/modules/packages/development.nix
# A "package catalog" that defines categorized lists of development tools.
{ pkgs, ... }:

{
  # Essential tools for building software from source
  buildTools = with pkgs; [
    pkg-config
    stdenv.cc
    gcc
    openssl.dev
    systemd
    # android-tools
    # n8n
    typst
    typstyle
    supabase-cli
    jq
    just
  ];

  # Large Graphical IDEs
  ides = with pkgs; [
    vscode
    jetbrains-toolbox
    gitkraken
    unityhub
    antigravity
    # ladybird  # this one is not an IDE itself!
    # It is an Open Source Web Browser! (test)
  ];

  # Language-Specific Toolchains (nested for clarity)
  lang = {
    kotlin = with pkgs; [
      gradle
      tomcat
      openjdk21
    ];
    python = with pkgs; [ uv ];
    rust = with pkgs; [ rustup ];
    go = with pkgs; [ go ];
    web = with pkgs; [
      nodejs
      bun
      deno
    ];
    iot = with pkgs; [ platformio ];
  };

  # These are the essential packages needed at RUNTIME for CUDA applications
  cudaPkgs = with pkgs; [
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    linuxPackages.nvidia_x11
  ];

}
