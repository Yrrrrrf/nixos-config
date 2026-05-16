#!/usr/bin/env nu
# screenshot.nu — Capture region or full screen via hyprshot.
use _shared.nu *

def main [--region --screen] {
    if $region {
        notify "Screenshot" "Select a region to capture"
        run_silent { hyprshot -m region }
    } else if $screen {
        run_silent { hyprshot -m output }
        notify "Screenshot" "Full screen saved"
    }
}
