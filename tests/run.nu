#!/usr/bin/env nu
# tests/run.nu — Umbrella test runner. Runs get.nu inline (no subprocess).
#
# Usage:
#   nu tests/run.nu              # non-destructive: get suite only
#   nu tests/run.nu --all        # full sweep including action verbs
#   nu tests/run.nu --set-only   # action verbs only
#
# Exit code: 0 = all pass, 1 = any fail.
use _lib.nu *

const REQUIRED = ["text" "tooltip" "class"]

const GET_CASES = [
    { name: "volume",          cmd: "volume",          args: ["--get"] }
    { name: "mic",             cmd: "mic",             args: ["--get-status"] }
    { name: "brightness",      cmd: "brightness",      args: ["--get"] }
    { name: "layout",          cmd: "layout",          args: ["--get"] }
    { name: "gpu-performance", cmd: "gpu-performance", args: ["--get"] }
    { name: "kbd-backlight",   cmd: "kbd-backlight",   args: ["--get"] }
]

const SET_CASES = [
    { name: "volume --mute",           run: { run-external "volume" "--mute" | complete } }
    { name: "mic --toggle",            run: { run-external "mic" "--toggle" | complete }
      snapshot: { (run-external "mic" "--get-status" | complete).stdout | str trim | from json | get class }
      verify: {|b| let a = ((run-external "mic" "--get-status" | complete).stdout | str trim | from json | get class); if $a != $b { null } else { $"class unchanged '($b)'" } }
    }
    { name: "brightness --up",         run: { run-external "brightness" "--up" | complete } }
    { name: "brightness --down",       run: { run-external "brightness" "--down" | complete } }
    { name: "layout --change",         run: { run-external "layout" "--change" | complete }
      snapshot: { (run-external "layout" "--get" | complete).stdout | str trim | from json | get class }
      verify: {|b| let a = ((run-external "layout" "--get" | complete).stdout | str trim | from json | get class); if $a != $b { null } else { $"class unchanged '($b)'" } }
    }
    { name: "gpu-performance --change", run: { run-external "gpu-performance" "--change" | complete }
      snapshot: { (run-external "gpu-performance" "--get" | complete).stdout | str trim | from json | get class }
      verify: {|b| let a = ((run-external "gpu-performance" "--get" | complete).stdout | str trim | from json | get class); if $a != $b { null } else { $"class unchanged '($b)'" } }
    }
    { name: "kbd-backlight --up",      run: { run-external "kbd-backlight" "--up" | complete } }
    { name: "kbd-backlight --down",    run: { run-external "kbd-backlight" "--down" | complete } }
]

# ── GET suite ──────────────────────────────────────────────────────────────────

def run_get [cases: list]: nothing -> bool {
    let results = ($cases | each {|c|
        let out = (run-external $c.cmd ...$c.args | complete)

        if $out.exit_code != 0 {
            let detail = ($out.stderr | str trim)
            let detail = if ($detail | is-empty) { $out.stdout | str trim } else { $detail }
            fail $c.name $detail
        } else {
            let raw = ($out.stdout | str trim)
            let json = (try_json $raw)
            if $json == null {
                fail $c.name $"not valid JSON:\n($raw)"
            } else {
                let issues = (field_issues $json $REQUIRED)
                if ($issues | is-empty) { pass $c.name } else { fail $c.name ($issues | str join "; ") }
            }
        }
    })

    # Print preview of what each script returned
    print $"(ansi cyan_bold)── Script output preview ──(ansi reset)"
    $cases | each {|c|
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

    report "Waybar --get contract" $results
}

# ── SET suite ──────────────────────────────────────────────────────────────────

def run_set [cases: list]: nothing -> bool {
    print $"(ansi yellow_bold)⚠  Destructive — real state changes(ansi reset)\n"
    let results = ($cases | each {|c|
        let before = if ($c | get -o snapshot) != null { do $c.snapshot } else { null }

        let out = (do $c.run)
        if $out.exit_code != 0 {
            let detail = ($out.stderr | str trim)
            let detail = if ($detail | is-empty) { $"exited ($out.exit_code)" } else { $detail }
            fail $c.name $detail
        } else {
            sleep 300ms
            if ($c | get -o verify) != null {
                let issue = (do $c.verify $before)
                if $issue != null { fail $c.name $issue } else { pass $c.name }
            } else {
                pass $c.name
            }
        }
    })
    report "Action verbs" $results
}

# ── Main ───────────────────────────────────────────────────────────────────────

def main [
    --all       # run both get + set suites
    --set-only  # run only action verbs (destructive)
] {
    print ""

    let get_ok = if $set_only { true } else { run_get $GET_CASES }
    let set_ok = if $all or $set_only { run_set $SET_CASES } else { true }

    if $get_ok and $set_ok {
        print $"(ansi green_bold)✓ All suites passed(ansi reset)"
        exit 0
    } else {
        print $"(ansi red_bold)✗ One or more suites failed(ansi reset)"
        exit 1
    }
}
