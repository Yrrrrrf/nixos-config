#!/usr/bin/env nu
# powermenu.nu — Session/power actions.
# No args = walker picker. With arg = dispatch directly.
use _shared.nu *

def pick []: nothing -> string {
    "Logout\nSuspend\nReboot\nShutdown"
    | walker --dmenu --placeholder "Power:"
    | str trim
}

def dispatch [action: string] {
    match $action {
        "Logout"   => { run_silent { hyprctl dispatch exit } }
        "Suspend"  => { run_silent { systemctl suspend } }
        "Reboot"   => { run_silent { systemctl reboot } }
        "Shutdown" => { run_silent { systemctl poweroff } }
        _          => { }
    }
}

def main [action?: string] {
    let chosen = (if ($action | is-empty) { pick } else { $action })
    if not ($chosen | is-empty) { dispatch $chosen }
}
