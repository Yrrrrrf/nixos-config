#!/usr/bin/env nu

# Power menu actions for Hyprland
def main [action: string] {
    match $action {
        "Logout" => { hyprctl dispatch exit }
        "Suspend" => { systemctl suspend }
        "Reboot" => { systemctl reboot }
        "Shutdown" => { systemctl poweroff }
        _ => { 
            print $"Unknown action: ($action)"
            exit 1
        }
    }
}
