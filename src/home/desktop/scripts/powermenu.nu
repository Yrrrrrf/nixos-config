#!/usr/bin/env nu
# powermenu.nu — Session/power actions.
#   No args  → open walker dmenu picker, dispatch the choice.
#   With arg → dispatch directly. Used by waybar on-click (no args)
#              and available for keybinds (e.g. `powermenu Suspend`).
use _shared.nu *

def open_picker [] {
    "Logout\nSuspend\nReboot\nShutdown"
    | walker --dmenu --prompt "Power:"
    | str trim
}

def dispatch [action: string] {
    match $action {
        "Logout"   => { run_silent { hyprctl dispatch exit } }
        "Suspend"  => { run_silent { systemctl suspend } }
        "Reboot"   => { run_silent { systemctl reboot } }
        "Shutdown" => { run_silent { systemctl poweroff } }
        _          => { }  # empty or unknown — silently no-op
    }
}

def main [action?: string] {
    let chosen = (if ($action | is-empty) { open_picker } else { $action })
    if not ($chosen | is-empty) { dispatch $chosen }
}
