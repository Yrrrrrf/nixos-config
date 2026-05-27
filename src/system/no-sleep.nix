{...}: {
  flake.nixosModules.no-sleep = {...}: {
    systemd.targets.sleep.enable        = false;
    systemd.targets.suspend.enable      = false;
    systemd.targets.hibernate.enable    = false;
    systemd.targets.hybrid-sleep.enable = false;

    services.logind = {
      lidSwitch              = "ignore";
      lidSwitchDocked        = "ignore";
      lidSwitchExternalPower = "ignore";
      extraConfig = ''
        IdleAction=ignore
        HandlePowerKey=ignore
      '';
    };
  };
}
