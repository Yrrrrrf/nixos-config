{...}: {
  flake.homeModules.hyprland =
    # /etc/nixos/modules/home/hyprland/hyprland.nix
    #
    # This module declaratively manages the Hyprland window manager via Home Manager.
    # It enables the service and specifies the package to use, while offloading the
    # detailed, imperative configuration to an adjacent 'hyprland.conf' file.
    {
      pkgs,
      lib,
      ...
    }: {
      # The 'wayland.windowManager.hyprland' options are provided by Home Manager's
      # built-in Hyprland module.
      wayland.windowManager.hyprland = {
        # This is the master switch to enable Hyprland.
        enable = true;

        # Explicitly specify the Hyprland package from nixpkgs.
        package = lib.mkDefault pkgs.hyprland;

        # This is the key to our modular setup. Instead of writing the entire
        # Hyprland configuration inside this Nix file (which is possible but cumbersome),
        # we tell it to read the configuration directly from another file.
        # This allows you to edit your Hyprland settings using its native syntax.
        # The path is relative to this .nix file.
        extraConfig = builtins.readFile ./hyprland.conf;
      };

      # --- Hyprland Lock Screen Configuration ---
      # Although hyprlock is a separate program, its configuration is tightly
      # coupled with the Hyprland session. We manage it here for co-location.
      programs.hyprlock = {
        enable = true; # Enables and configures hyprlock.

        # Similar to Hyprland, we load its theme and settings from an external file.
        # We will create this file in a later step.
        # extraConfig = builtins.readFile ../desktop/hyprlock.conf;
      };
    };
}
