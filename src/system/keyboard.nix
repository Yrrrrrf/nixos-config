{...}: {
  flake.nixosModules.keyboard = {config, ...}: {
    # XKB option lives under services.xserver.xkb even without X11 enabled.
    # services.xserver.enable stays false — this tree is just where NixOS
    # parks the option schema.
    services.xserver.xkb.options = "caps:swapescape,grp:super_escape_toggle";

    # Without this, the TTY console keeps the default keymap and the swap
    # doesn't apply before hyprland starts.
    console.useXkbConfig = true;

    # Hyprland reads XKB_DEFAULT_OPTIONS at startup. Exporting it from the
    # NixOS option keeps a single source of truth: edit it in one place,
    # it propagates to TTY + Hyprland + any future compositor.
    environment.variables.XKB_DEFAULT_OPTIONS = config.services.xserver.xkb.options;
  };
}
