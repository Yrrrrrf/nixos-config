# /etc/nixos/home/modules/packages/cli.nix
{ pkgs, ... }: {
  replacements = with pkgs; [
    ripgrep
    eza
    bat
    fd
    fzf
    killport
    lazygit
  ];

  # A list of general-purpose and fun command-line tools
  tools = with pkgs; [
    git
    helix
    btop
    unimatrix
    neofetch
    tree
    p7zip
  ];
}
