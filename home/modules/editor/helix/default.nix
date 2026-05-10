{pkgs, ...}: {
  imports = [
    ./settings.nix
  ];
  programs.helix.enable = true;
}
