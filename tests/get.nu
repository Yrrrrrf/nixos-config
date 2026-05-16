#!/usr/bin/env nu
# tests/get.nu — Verify every waybar script emits valid {text, tooltip, class} JSON.
#
# Usage:
#   nu tests/get.nu              # all scripts
#   nu tests/get.nu volume       # one script by name
#
# Exit code: 0 = all pass, 1 = any fail.
use _lib.nu *

const REQUIRED = ["text" "tooltip" "class"]

const CASES = [
    { name: "volume",          cmd: "volume",          args: ["--get"] }
    { name: "mic",             cmd: "mic",             args: ["--get-status"] }
    { name: "brightness",      cmd: "brightness",      args: ["--get"] }
    { name: "layout",          cmd: "layout",          args: ["--get"] }
    { name: "gpu-performance", cmd: "gpu-performance", args: ["--get"] }
    { name: "kbd-backlight",   cmd: "kbd-backlight",   args: ["--get"] }
]

def check_case [c: record]: nothing -> record {
    let out = (run-external $c.cmd ...$c.args | complete)

    if $out.exit_code != 0 {
        let stderr = ($out.stderr | str trim)
        let stdout = ($out.stdout | str trim)
        let detail = (
            if ($stderr | is-not-empty) { $stderr }
            else if ($stdout | is-not-empty) { $stdout }
            else { $"exited ($out.exit_code) with no output" }
        )
        return (fail $c.name $detail)
    }

    let raw = ($out.stdout | str trim)
    if ($raw | is-empty) {
        return (fail $c.name "no output (empty stdout)")
    }

    let json = (try_json $raw)
    if $json == null {
        return (fail $c.name $"not valid JSON:\n($raw)")
    }

    let issues = (field_issues $json $REQUIRED)
    if ($issues | is-empty) {
        # Show the parsed values so you can visually confirm them
        pass $c.name
    } else {
        fail $c.name ($issues | str join "; ")
    }
}

def main [filter?: string] {
    let cases = (
        if ($filter | is-empty) { $CASES }
        else { $CASES | where name =~ $filter }
    )

    if ($cases | is-empty) {
        print $"(ansi red)No case matches '($filter)'(ansi reset)"
        print $"Available: ($CASES | get name | str join ', ')"
        exit 1
    }

    let results = ($cases | each { check_case $in })

    # Print what each script actually returned (handy sanity check)
    print $"(ansi cyan_bold)── Script output preview ──(ansi reset)"
    $cases | each {|c|
        let out = (run-external $c.cmd ...$c.args | complete)
        let raw = ($out.stdout | str trim)
        let json = (try_json $raw)
        let preview = if $json != null {
            $"text=(ansi yellow)($json.text)(ansi reset)  tooltip=(ansi dark_gray)($json.tooltip)(ansi reset)  class=(ansi cyan)($json.class)(ansi reset)"
        } else {
            $"(ansi red)($raw)(ansi reset)"
        }
        print $"  ($c.name): ($preview)"
    } | ignore
    print ""

    let ok = (report "Waybar --get contracts" $results)
    if not $ok { exit 1 }
}
