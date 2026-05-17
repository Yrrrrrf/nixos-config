#!/usr/bin/env nu
# tests/run.nu — Umbrella test runner.
#
# Usage (from the tests/ directory):
#   nu run.nu              # non-destructive: get suite only
#   nu run.nu --all        # get + set suites (destructive)
#   nu run.nu --set-only   # action verbs only (destructive)
#
# Exit code: 0 = all pass, 1 = any fail.
use _lib.nu *

# ── GET suite ──────────────────────────────────────────────────────────────────

def get_cases []: nothing -> list {
    return [
        { name: "volume",          cmd: "volume",          args: ["--get"] }
        { name: "mic",             cmd: "mic",             args: ["--get-status"] }
        { name: "brightness",      cmd: "brightness",      args: ["--get"] }
        { name: "layout",          cmd: "layout",          args: ["--get"] }
        { name: "gpu-performance", cmd: "gpu-performance", args: ["--get"] }
        { name: "kbd-backlight",   cmd: "kbd-backlight",   args: ["--get"] }
    ]
}

def check_get [c: record]: nothing -> record {
    let required = ["text" "tooltip" "class"]
    let out = (run-external $c.cmd ...$c.args | complete)

    if $out.exit_code != 0 {
        let stderr = ($out.stderr | str trim)
        let detail = if ($stderr | is-empty) { $out.stdout | str trim } else { $stderr }
        return (fail $c.name $detail)
    }

    let raw = ($out.stdout | str trim)
    if ($raw | is-empty) { return (fail $c.name "no output") }

    let json = (try_json $raw)
    if $json == null { return (fail $c.name $"not valid JSON: ($raw)") }

    let issues = (field_issues $json $required)
    if ($issues | is-empty) { pass $c.name } else { fail $c.name ($issues | str join "; ") }
}

def run_get []: nothing -> bool {
    let cases = (get_cases)
    let results = ($cases | each { check_get $in })

    # Preview: what each script actually returned right now
    print $"(ansi cyan_bold)── Script output ──(ansi reset)"
    $cases | each {|c|
        let out = (run-external $c.cmd ...$c.args | complete)
        let json = (try_json ($out.stdout | str trim))
        let preview = if $json != null {
            $"text=(ansi yellow)($json.text)(ansi reset)  tooltip=(ansi dark_gray)($json.tooltip)(ansi reset)  class=(ansi cyan)($json.class)(ansi reset)"
        } else {
            $"(ansi red)($out.stdout | str trim)(ansi reset)"
        }
        print $"  ($c.name): ($preview)"
    } | ignore
    print ""

    report "Waybar --get contract" $results
}

# ── SET suite ──────────────────────────────────────────────────────────────────

def set_cases []: nothing -> list {
    return [
        { name: "volume --mute"
          run:  { run-external "volume" "--mute" | complete }
        }
        { name: "mic --toggle"
          run:      { run-external "mic" "--toggle" | complete }
          snapshot: { run-external "mic" "--get-status" | complete | get stdout | str trim | from json | get class }
          verify:   {|b| let a = (run-external "mic" "--get-status" | complete | get stdout | str trim | from json | get class); if $a != $b { null } else { $"unchanged '($b)'" } }
        }
        { name: "brightness --up"
          run:  { run-external "brightness" "--up" | complete }
        }
        { name: "brightness --down"
          run:  { run-external "brightness" "--down" | complete }
        }
        { name: "layout --change"
          run:      { run-external "layout" "--change" | complete }
          snapshot: { run-external "layout" "--get" | complete | get stdout | str trim | from json | get class }
          verify:   {|b| let a = (run-external "layout" "--get" | complete | get stdout | str trim | from json | get class); if $a != $b { null } else { $"unchanged '($b)'" } }
        }
        { name: "gpu-performance --change"
          run:      { run-external "gpu-performance" "--change" | complete }
          snapshot: { run-external "gpu-performance" "--get" | complete | get stdout | str trim | from json | get class }
          verify:   {|b| let a = (run-external "gpu-performance" "--get" | complete | get stdout | str trim | from json | get class); if $a != $b { null } else { $"unchanged '($b)'" } }
        }
        { name: "kbd-backlight --up"
          run:  { run-external "kbd-backlight" "--up" | complete }
        }
        { name: "kbd-backlight --down"
          run:  { run-external "kbd-backlight" "--down" | complete }
        }
    ]
}

def check_set [c: record]: nothing -> record {
    let before = if ($c | get -o snapshot) != null { do $c.snapshot } else { null }

    let out = (do $c.run)
    if $out.exit_code != 0 {
        let stderr = ($out.stderr | str trim)
        let detail = if ($stderr | is-empty) { $"exited ($out.exit_code)" } else { $stderr }
        return (fail $c.name $detail)
    }

    sleep 300ms

    if ($c | get -o verify) != null {
        let issue = (do $c.verify $before)
        if $issue != null { return (fail $c.name $issue) }
    }

    pass $c.name
}

def run_set []: nothing -> bool {
    print $"(ansi yellow_bold)⚠  Destructive — real state changes will happen(ansi reset)\n"
    let results = (set_cases | each { check_set $in })
    report "Action verbs" $results
}

# ── Main ───────────────────────────────────────────────────────────────────────

def main [
    --all       # run both get + set suites (destructive)
    --set-only  # run only action verbs (destructive)
] {
    print ""
    let get_ok = if $set_only { true } else { run_get }
    let set_ok = if ($all or $set_only) { run_set } else { true }

    if ($get_ok and $set_ok) {
        print $"(ansi green_bold)✓ All suites passed(ansi reset)"
        exit 0
    } else {
        print $"(ansi red_bold)✗ One or more suites failed(ansi reset)"
        exit 1
    }
}
