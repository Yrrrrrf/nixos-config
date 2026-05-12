{...}: {
  flake.nixosModules.g14-networking = {
    config,
    pkgs,
    ...
  }: {
    networking.hostName = "g14";

    networking.networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    networking.extraHosts = ''
      127.0.0.1   traefik.localhost
      127.0.0.1   api.localhost
      127.0.0.1   app.localhost
    '';

    networking.firewall = {
      enable = true;
      allowedTCPPorts = [53];
      allowedUDPPorts = [
        53
        67
      ];
    };

    networking.nat = {
      enable = true;
      enableIPv6 = true;
      internalInterfaces = ["wlp2s0"];
      externalInterface = "enp101s0f3u2c2";
    };
  };
}
