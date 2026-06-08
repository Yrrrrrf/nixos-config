{...}: {
  flake.nixosModules.services = {...}: {
    # --- Core System Services ---
    services.udisks2.enable = true;
    services.pipewire.enable = true;
    security.rtkit.enable = true;
    services.openssh.enable = true;
  };
}
