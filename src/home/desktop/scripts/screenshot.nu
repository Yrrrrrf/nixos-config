#!/usr/bin/env nu
# screenshot.nu — Capture region or full screen via hyprshot.
# Output is pinned to ~/Pictures/Screenshots/; hyprshot picks the filename.
# hyprshot forks a background wl-copy that holds inherited fds while it serves
# the clipboard, so we cannot pipe it through run_silent (complete would wait
# forever for the pipe to drain). Bare call + stdio→/dev/null returns as soon
# as hyprshot itself exits.
use _shared.nu *
const SCREENSHOT_DIR = "~/Pictures/Screenshots"
def ensure_dir []: nothing -> string {
    let dir = ($SCREENSHOT_DIR | path expand)
    mkdir $dir
    $dir
}
def main [--region, --screen] {
    let dir = (ensure_dir)
    if $region {
        notify "Screenshot" "Select a region to capture"
        hyprshot -m region -o $dir out> /dev/null err> /dev/null
    } else if $screen {
        hyprshot -m output -o $dir out> /dev/null err> /dev/null
        notify "Screenshot" "Full screen saved"
    }
}
