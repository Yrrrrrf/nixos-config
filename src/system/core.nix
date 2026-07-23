{...}: {
  flake.nixosModules.core = {...}: {
    # --- System Bootloader Configuration ---
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.memtest86.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 10;

    # --- Timezone and Internationalisation Settings ---
    time.timeZone = "America/Mexico_City";
    i18n.defaultLocale = "en_US.UTF-8";

    # --- Nix and System Management ---
    nix.settings = {
      extra-substituters = ["https://walker-git.cachix.org"];
      extra-trusted-public-keys = [
        "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      ];
    };

    programs.nh = {
      enable = true;
      flake = "/etc/nixos";
      clean.enable = true;
      clean.dates = "weekly";
      clean.extraArgs = "--keep 5 --keep-since 7d";
    };

    # --- Foreign Binary Support ---
    programs.nix-ld.enable = true;

    # --- Core System Services ---
    services.udisks2.enable = true;
    services.pipewire.enable = true;
    security.rtkit.enable = true;
    services.openssh.enable = true;
  };
}
