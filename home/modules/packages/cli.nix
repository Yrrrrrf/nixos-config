# /etc/nixos/home/modules/packages/cli.nix
{ pkgs, ... }:
{
  replacements = with pkgs; [
    ripgrep
    eza
    bat
    fd
    fzf
    killport
    lazygit
    lazydocker
    sd
  ];

  typingTools = with pkgs; [
    ttyper
    wev
  ];

  # A list of general-purpose and fun command-line tools
  tools = with pkgs; [
    openssl
    git
    gh
    helix
    btop
    unimatrix
    neofetch
    tree
    p7zip
    bluetui
    impala
  ];
}
