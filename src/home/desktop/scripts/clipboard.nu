#!/usr/bin/env nu
# clipboard.nu — Clipboard picker via walker's native elephant provider.
# History and image previews are managed by elephant's clipboard provider.
use _shared.nu *
def main [--pick] {
    if $pick {
        run_silent { walker --provider clipboard --placeholder "Clipboard:" }
    }
}
