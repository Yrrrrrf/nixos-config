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

  networking.extraHosts = ''
    127.0.0.1   traefik.localhost
    127.0.0.1   api.localhost
    127.0.0.1   app.localhost
  '';

  services.openssh.enable = true;
}
