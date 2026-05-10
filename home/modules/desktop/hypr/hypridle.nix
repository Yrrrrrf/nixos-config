# /etc/nixos/modules/home/hyprland/hypridle.nix
#
# This file declaratively manages the configuration for the hypridle daemon,
# which handles system events during user inactivity (like locking the screen,
# suspending the system, or turning off displays).
{pkgs, ...}: {
  # This is the main Home Manager option for the hypridle service.
  services.hypridle = {
    enable = true;
    package = pkgs.hypridle; # Explicitly specify the package to use.

    # The 'settings' attribute set allows for a fully declarative
    # configuration directly within Nix, which is the preferred method.
    settings = {
      # General settings for hypridle.
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Command to run when locking. Checks if lock is running.
        before_sleep_cmd = "loginctl lock-session"; # Lock the screen before sleeping.
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn displays on after waking up.
      };

      # Define listeners for different timeouts.
      # Because there are multiple listeners, this is a list of attribute sets.
      listener = [
        {
          # Listener for locking the screen after 5 minutes of inactivity.
          timeout = 300; # 300 seconds = 5 minutes
          on-timeout = "loginctl lock-session"; # Lock the screen.
        }
        {
          # Listener for turning off the displays after 10 minutes of inactivity.
          timeout = 600; # 600 seconds = 10 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Turn displays off.
          on-resume = "hyprctl dispatch dpms on"; # Turn them back on when activity resumes.
        }
        {
          # Listener for suspending the system after 30 minutes of inactivity.
          timeout = 1800; # 1800 seconds = 30 minutes
          on-timeout = "systemctl suspend"; # Suspend the system.
        }
      ];
    };
  };
}
