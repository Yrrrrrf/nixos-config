#!/usr/bin/env nu
# clipboard.nu — cliphist picker via walker, copies selection back.
# History is fed by `wl-paste --watch cliphist store` (hyprland exec-once).
# wl-copy daemonizes and holds inherited fds (same issue as hyprshot in
# screenshot.nu), so the final pipe stage gets stdio→/dev/null.
use _shared.nu *
def prompt []: nothing -> string {
    cliphist list | walker --dmenu --placeholder "Clipboard:" | str trim
}
def main [--pick] {
    if $pick {
        let chosen = (prompt)
        if not ($chosen | is-empty) {
            $chosen | cliphist decode | wl-copy out> /dev/null err> /dev/null
        }
    }
}
