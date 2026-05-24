#!/usr/bin/env nu
# tests/get.nu — Verify every waybar script emits valid {text, tooltip, class} JSON.
#
# Usage:
#   nu tests/get.nu              # all scripts
#   nu tests/get.nu volume       # one script by name
#
# Exit code: 0 = all pass, 1 = any fail.
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

    if $out.exit_code != 0 {
        let detail = ($out.stderr | str trim)
        let detail = if ($detail | is-empty) { $out.stdout | str trim } else { $detail }
        return (fail $c.name $detail)
    }

    let raw = ($out.stdout | str trim)
    if ($raw | is-empty) { return (fail $c.name "no output (empty stdout)") }

    let json = (try_json $raw)
    if $json == null { return (fail $c.name $"not valid JSON:\n($raw)") }

    let issues = (field_issues $json $required)
    if ($issues | is-empty) { pass $c.name } else { fail $c.name ($issues | str join "; ") }
}

def main [filter?: string] {
    let all_cases = (cases)
    let selected = (
        if ($filter | is-empty) { $all_cases }
        else { $all_cases | where name =~ $filter }
    )

    if ($selected | is-empty) {
        print $"(ansi red)No case matches '($filter)'(ansi reset)"
        print $"Available: ($all_cases | get name | str join ', ')"
        exit 1
    }

    let results = ($selected | each { check_case $in })

    # Preview table
    print $"(ansi cyan_bold)── Script output preview ──(ansi reset)"
    $selected | each {|c|
        let out = (run-external $c.cmd ...$c.args | complete)
        let json = (try_json ($out.stdout | str trim))
        let preview = if $json != null {
            [
                $"text=(ansi yellow)($json.text)(ansi reset)"
                $"tooltip=(ansi dark_gray)($json.tooltip)(ansi reset)"
                $"class=(ansi cyan)($json.class)(ansi reset)"
            ] | str join "  "
        } else {
            $"(ansi red)($out.stdout | str trim)(ansi reset)"
        }
        print $"  (ansi bold)($c.name)(ansi reset): ($preview)"
    } | ignore
    print ""

    let ok = (report "Waybar --get contracts" $results)
    if not $ok { exit 1 }
}
