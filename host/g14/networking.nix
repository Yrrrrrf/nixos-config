# /etc/nixos/networking.nix
# Corrected version using the 'ensureProfiles' option for NetworkManager.

{
  config,
  pkgs,
  ...
}:

{
  networking.hostName = "G14";

  networking.networkmanager.enable = true;

  services.openssh.enable = true;
}
