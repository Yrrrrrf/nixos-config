#!/usr/bin/env nu
# tests/ui-get.nu — Verify waybar status scripts JSON contracts
use _lib.nu *

def cases [] { [
    { name: "volume",          cmd: "volume",          args: ["--get"] }
    { name: "mic",             cmd: "mic",             args: ["--get-status"] }
    { name: "brightness",      cmd: "brightness",      args: ["--get"] }
    { name: "layout",          cmd: "layout",          args: ["--get"] }
    { name: "gpu-performance", cmd: "gpu-performance", args: ["--get"] }
    { name: "kbd-backlight",   cmd: "kbd-backlight",   args: ["--get"] }
] }

def check_case [c: record]: nothing -> record {
    let required = ["text" "tooltip" "class"]
    let out = (run-external $c.cmd ...$c.args | complete)
    if $out.exit_code != 0 { return (fail $c.name "script failed") }
    let raw = ($out.stdout | str trim)
    let json = (try_json $raw)
    if $json == null { return (fail $c.name "invalid JSON") }
    let issues = (field_issues $json $required)
    check $c.name ($issues | is-empty) ($issues | str join "; ")
}

def main [] {
    audit "UI Contract Verification" "cyan_bold" {
        cases | each { check_case $in }
    }
}
