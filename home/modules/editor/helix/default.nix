{ pkgs, ... }:
{
  imports = [
    ./settings.nix
    ./langs/default.nix
  ];
  programs.helix.enable = true;
}
