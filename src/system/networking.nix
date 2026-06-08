{...}: {
  flake.nixosModules.networking = {...}: {
    # ── iwd standalone ────────────────────────────────────────────────
    # impala speaks D-Bus directly to iwd. NetworkManager is removed
    # so nothing else asserts state on the wireless device.
    networking.wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = true; # iwd handles DHCP itself
          AddressRandomization = "network"; # randomize MAC per SSID
        };
        Network = {
          EnableIPv6 = true;
          NameResolvingService = "systemd"; # write to systemd-resolved
        };
      };
    };

    # iwd writes DNS via resolved; turn it on.
    services.resolved.enable = true;

    # hardware-configuration.nix sets `networking.useDHCP = true`, which
    # enables dhcpcd globally. Keep it (USB-ethernet uplink uses it), but
    # keep dhcpcd off wlp2s0 so it doesn't race iwd for the lease.
    networking.dhcpcd.denyInterfaces = ["wlp2s0"];

    networking.extraHosts = ''
      127.0.0.1   traefik.localhost
      127.0.0.1   api.localhost
      127.0.0.1   app.localhost
    '';

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [53];
      allowedUDPPorts = [53 67];
    };

    # NAT sharing USB-ethernet uplink → wifi clients.
    # Layer 3, agnostic to wifi backend — keeps working.
    networking.nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = ["wlp2s0"];
      externalInterface = "enp101s0f3u2c2";
    };

    # Bluetooth configuration (moved from services.nix)
    # todo: Check the bluetooth once changed to AX210
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
