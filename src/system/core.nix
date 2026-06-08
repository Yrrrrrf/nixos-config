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
  };
}
