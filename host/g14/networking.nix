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

  networking.firewall = {
    enable = true;
    # Open ports for DNS (53) and DHCP (67) so clients can get IPs
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 67 ];
    
    # If you want to be extra specific, you can trust the wireless interface
    # (Replace 'wlp2s0' with your actual wifi interface name from `ip a`)
    # trustedInterfaces = [ "wlp2s0" ]; 
  };

  # Enable NAT (Network Address Translation) so packets from WiFi 
  # can go out through Ethernet.
  # Note: NetworkManager usually handles this automatically in "Hotspot" mode, 
  # but enabling it here ensures the kernel modules are loaded.
  networking.nat = {
    enable = true;
    enableIPv6 = true;
    # "internal" is the interface you are sharing WITH (WiFi)
    # "external" is the interface you are sharing FROM (Ethernet)
    # You can find these names by running `ip a` in terminal.
    internalInterfaces = [ "wlp2s0" ]; 
    externalInterface = "enp101s0f3u2c2"; # Example name, check yours!
  };

}
