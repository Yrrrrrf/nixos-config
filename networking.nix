# /etc/nixos/networking.nix
# Corrected version using the 'ensureProfiles' option for NetworkManager.

{ config, pkgs, ... }:

{
  networking.hostName = "G14";

  # This remains correct. We are telling NixOS to use NetworkManager.
  networking.networkmanager.enable = true;

  # This is the correct declarative method for adding connection profiles
  # that NetworkManager will use.
  #networking.networkmanager.ensureProfiles.profiles = {
  #  # Each attribute here is a new connection profile.
  #  # The name "TotalPlay_Sala_5Grapida_Profile" is arbitrary but should be unique.
  #  "TotalPlay_Sala_5Grapida_Profile" = {
  #    connection = {
  #      id = "TP_S_5G";
  #      type = "wifi";
  #      autoconnect = true;
  #    };
  #    wifi = {
  #      ssid = "TotalPlay_Sala_5Grapida";
  #    };
  #    "wifi-security" = {
  #      key-mgmt = "wpa-psk";
  #      psk = "madonna1";
  #    };
  #  };

  #  "TotalPlay_Sala_2.4Grapida_Profilee" = {
  #    connection = {
  #      id = "TP_S_2.4G";
  #      type = "wifi";
  #      autoconnect = true;
  #    };
  #    wifi = {
  #      ssid = "TotalPlay_Sala_2.4Gnormal";
  #    };
  #    "wifi-security" = {
  #      key-mgmt = "wpa-psk";
  #      psk = "madonna1";
  #    };
  #  };

  #  "speed_Profile" = {
  #    connection = {
  #      id = "speed";
  #      type = "wifi";
  #      autoconnect = true;
  #    };
  #    wifi = {
  #      ssid = "speed";
  #    };
  #    "wifi-security" = {
  #      key-mgmt = "wpa-psk";
  #      psk = "madonna1";
  #    };
  #  };
  # };

  services.openssh.enable = true;
}
