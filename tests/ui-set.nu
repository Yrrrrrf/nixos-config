#!/usr/bin/env nu
# tests/ui-set.nu — Exercise UI action verbs
use _lib.nu *

def cases [] { [
    { name: "volume --mute", run: { run-external "volume" "--mute" | complete } }
    { name: "brightness --up", run: { run-external "brightness" "--up" | complete } }
    { name: "layout --change", run: { run-external "layout" "--change" | complete } }
] }

def check_case [c: record]: nothing -> record {
    let out = (do $c.run)
    check $c.name ($out.exit_code == 0) "action failed"
}

def main [] {
    audit "UI Set actions" "yellow_bold" {
        print $"(ansi yellow_bold)⚠  Destructive UI Actions(ansi reset)"
        cases | each { check_case $in }
    }
}
