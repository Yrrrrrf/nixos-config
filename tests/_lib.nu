# _lib.nu — Shared helpers for nu test suites.
# Each test returns: { name: string, passed: bool, skipped: bool, detail: string }

export def pass [name: string] {
    { name: $name, passed: true, skipped: false, detail: "" }
}

export def fail [name: string, detail: string = ""] {
    { name: $name, passed: false, skipped: false, detail: $detail }
}

export def skip [name: string, detail: string = ""] {
    { name: $name, passed: true, skipped: true, detail: $detail }
}

# Boolean helper: pass if true, fail if false
export def check [name: string, cond: bool, detail: string = ""] {
    if $cond { pass $name } else { fail $name $detail }
}

# Run command and check exit code
export def check_exec [name: string, cmd: string, args: list = []] {
    if (which $cmd | is-empty) { return (skip $name $"($cmd) not found") }
    let out = (run-external $cmd ...$args | complete)
    check $name ($out.exit_code == 0) ($out.stderr | str trim)
}

# Run command and grep for pattern
export def check_grep [name: string, cmd: string, args: list, pattern: string, inverse: bool = false] {
    if (which $cmd | is-empty) { return (skip $name $"($cmd) not found") }
    let out = (run-external $cmd ...$args | complete)
    let has = ($out.stdout | str contains $pattern)
    let ok = if $inverse { not $has } else { $has }
    check $name $ok ($out.stdout | str trim)
}

# Parse JSON safely — returns null on failure instead of throwing.
export def try_json [text: string]: nothing -> any {
    try { $text | from json } catch { null }
}

# Check a record has all required keys with non-empty string values.
# Returns a (possibly empty) list of error strings.
export def field_issues [rec: record, required: list]: nothing -> list {
    $required | each {|f|
        let v = ($rec | get -o $f)
        if $v == null { $"missing ($f)" } else if ($v | is-empty) { $"empty ($f)" } else { null }
    } | compact
}

# Print a suite header + each result, return overall pass/fail bool.
export def report [title: string, results: list]: nothing -> bool {
    let passed  = ($results | where passed and (not skipped) | length)
    let skipped = ($results | where skipped | length)
    let total   = ($results | length)
    let ok      = ($results | all {|r| $r.passed})

    let header_color = if $ok { "green_bold" } else { "red_bold" }
    let status_line = if $skipped > 0 {
        $"($passed)/($total) passed, ($skipped) skipped"
    } else {
        $"($passed)/($total)"
    }
    
    print $"(ansi $header_color)── ($title)(ansi reset)  (ansi dark_gray)($status_line)(ansi reset)"

    $results | each {|r|
        if $r.skipped {
            print $"  (ansi yellow)~(ansi reset) (ansi yellow)($r.name)(ansi reset)"
            if ($r.detail | is-not-empty) {
                print $"    (ansi dark_gray)($r.detail)(ansi reset)"
            }
        } else if $r.passed {
            print $"  (ansi green)✓(ansi reset) ($r.name)"
        } else {
            print $"  (ansi red)✗(ansi reset) (ansi red)($r.name)(ansi reset)"
            if ($r.detail | is-not-empty) {
                $r.detail | split row "\n" | each {|line|
                    print $"    (ansi dark_gray)($line)(ansi reset)"
                } | ignore
            }
        }
    } | ignore

    print ""
    $ok
}

# Standardized audit runner for individual test files
export def audit [title: string, color: string, block: closure] {
    print $"(char nl)(ansi $color)━━ ($title) Audit ━━(ansi reset)"
    let results = (do $block)
    report ($title + " checks") ($results | flatten)
}

# Master orchestrator for health.nu and bench.nu
export def orchestrate [
    title: string, 
    color: string, 
    suites: list, 
    --silent-success # If true, only show results on failure (good for health checks)
] {
    let BLUE = (ansi $color)
    let GREEN = (ansi green_bold)
    let RED = (ansi red_bold)
    let GRAY = (ansi dark_gray)
    let NC = (ansi reset)
    let CHECK = "✓"
    let CROSS = "✗"
    let ARROW = "→"
    let BULLET = "•"

    print $"(char nl)($BLUE)━━ ($title) ━━($NC)(char nl)"

    let results = ($suites | enumerate | each {|s|
        let i = $s.index + 1
        let total = ($suites | length)
        let label = $s.item.name
        let args = ($s.item | get -o args | default [])
        
        if $silent_success {
            print -n $"(char tab)($GRAY)($BULLET) ($label)($NC) ($GRAY)[($i)/($total)]($NC) "
            let out = (nu $"tests/($s.item.script)" ...$args | complete)
            if $out.exit_code == 0 {
                print $"($GREEN)($CHECK)($NC)"
                { name: $label, ok: true }
            } else {
                print $"($RED)($CROSS)($NC)"
                { name: $label, ok: false, log: ([$out.stdout $out.stderr] | str join (char nl)) }
            }
        } else {
            print $"(char tab)($BLUE)($ARROW) ($label)($NC) ($GRAY)[($i)/($total)]($NC)"
            let out = (nu $"tests/($s.item.script)" ...$args | complete)
            
            # Print both stdout and stderr indented
            let combined = ([$out.stdout $out.stderr] | str join (char nl) | str trim)
            if ($combined | is-not-empty) {
                print ($combined | lines | each {|l| $"(char tab)  ($l)" } | str join (char nl))
            }

            if $out.exit_code == 0 {
                print $"(char tab)($GREEN)($CHECK) ($label) complete($NC)(char nl)"
                { name: $label, ok: true }
            } else {
                print $"(char tab)($RED)($CROSS) ($label) failed($NC)(char nl)"
                { name: $label, ok: false, log: $out.stderr }
            }
        }
    })

    let failed = ($results | where not ok)
    let passed = ($results | where ok | length)
    let total = ($results | length)

    print $"(char nl)($ARROW) Summary: ($passed)/($total) passed"

    if ($failed | is-empty) {
        print $"($GREEN)($CHECK) ($title) SUCCESSFUL($NC)"
        exit 0
    } else {
        print $"($RED)($CROSS) ($title) DETECTED ISSUES($NC)"
        if $silent_success {
            $failed | each {|f|
                print $"(char nl)  ($RED)($BULLET) ($f.name) Details:($NC)"
                $f.log | lines | each {|l| print $"    ($GRAY)($l)($NC)" } | ignore
            } | ignore
        }
        exit 1
    }
}


