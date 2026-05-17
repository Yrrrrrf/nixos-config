#!/usr/bin/env nu
# tests/set.nu — Exercise every action verb. Where possible, verifies state changed.
#
# Usage:
#   nu tests/set.nu              # all actions
#   nu tests/set.nu volume       # filter by prefix
#
# ⚠  Real state changes. Re-run to restore original state.
# Exit code: 0 = all pass, 1 = any fail.
use _lib.nu *

def cases [] { [
    {
        name: "volume --mute"
        run:  { run-external "volume" "--mute" | complete }
    }
    {
        name: "mic --toggle"
        run:      { run-external "mic" "--toggle" | complete }
        snapshot: { run-external "mic" "--get-status" | complete | get stdout | str trim | from json | get class }
        verify:   {|b|
            let a = (run-external "mic" "--get-status" | complete | get stdout | str trim | from json | get class)
            if $a != $b { null } else { $"class unchanged '($b)'" }
        }
    }
    {
        name: "brightness --up"
        run:  { run-external "brightness" "--up" | complete }
    }
    {
        name: "brightness --down"
        run:  { run-external "brightness" "--down" | complete }
    }
    {
        name: "layout --change"
        run:      { run-external "layout" "--change" | complete }
        snapshot: { run-external "layout" "--get" | complete | get stdout | str trim | from json | get class }
        verify:   {|b|
            let a = (run-external "layout" "--get" | complete | get stdout | str trim | from json | get class)
            if $a != $b { null } else { $"class unchanged '($b)'" }
        }
    }
    {
        name: "gpu-performance --change"
        run:      { run-external "gpu-performance" "--change" | complete }
        snapshot: { run-external "gpu-performance" "--get" | complete | get stdout | str trim | from json | get class }
        verify:   {|b|
            let a = (run-external "gpu-performance" "--get" | complete | get stdout | str trim | from json | get class)
            if $a != $b { null } else { $"class unchanged '($b)'" }
        }
    }
    {
        name: "kbd-backlight --up"
        run:  { run-external "kbd-backlight" "--up" | complete }
    }
    {
        name: "kbd-backlight --down"
        run:  { run-external "kbd-backlight" "--down" | complete }
    }
] }

def check_case [c: record]: nothing -> record {
    let before = if ($c | get -o snapshot) != null { do $c.snapshot } else { null }

    let out = (do $c.run)
    if $out.exit_code != 0 {
        let detail = ($out.stderr | str trim)
        let detail = if ($detail | is-empty) { $"exited ($out.exit_code)" } else { $detail }
        return (fail $c.name $detail)
    }

    sleep 300ms

    if ($c | get -o verify) != null {
        let issue = (do $c.verify $before)
        if $issue != null { return (fail $c.name $issue) }
    }

    pass $c.name
}

def main [filter?: string] {
    let all_cases = (cases)
    let selected = (
        if ($filter | is-empty) { $all_cases }
        else { $all_cases | where {|c| $c.name | str starts-with $filter} }
    )

    if ($selected | is-empty) {
        print $"(ansi red)No case matches '($filter)'(ansi reset)"
        print $"Available: ($all_cases | get name | str join ', ')"
        exit 1
    }

    print $"(ansi yellow_bold)⚠  Destructive — real state changes will happen(ansi reset)\n"
    let results = ($selected | each { check_case $in })
    let ok = (report "Action verbs" $results)
    if not $ok { exit 1 }
}
