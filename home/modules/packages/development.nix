# /etc/nixos/home/modules/packages/development.nix
# A "package catalog" that defines categorized lists of development tools.
{ pkgs, ... }:

{
  # Essential tools for building software from source
  buildTools = with pkgs; [
    pkg-config
    stdenv.cc
    gcc
    openssl
    systemd
  ];

  # Large Graphical IDEs
  ides = with pkgs; [
    vscode
    jetbrains.goland
    jetbrains.datagrip
    jetbrains.idea-ultimate
    gitkraken
  ];

  # Language-Specific Toolchains (nested for clarity)
  lang = {
    kotlin = with pkgs; [ gradle tomcat ];
    python = with pkgs; [ uv ];
    rust = with pkgs; [ rustup ];
    go = with pkgs; [ go ];
    web = with pkgs; [ nodejs bun deno ];
    # You can easily add a 'kotlin' or 'java' section here later
  };
}
