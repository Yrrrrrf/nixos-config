# Shared helpers for nu test suites.
# Each test returns a record: { name: string, passed: bool, detail: string }
# Suites are lists of those records; `report` prints + summarises one suite.

export def pass [name: string] {
    { name: $name, passed: true, detail: "" }
}

export def fail [name: string, detail: string = ""] {
    { name: $name, passed: false, detail: $detail }
}

# Functional gate: condition -> pass/fail with optional failure detail.
export def check [name: string, condition: bool, detail: string = ""] {
    if $condition { pass $name } else { fail $name $detail }
}

# Print one suite, return whether everything passed.
export def report [title: string, results: list]: nothing -> bool {
    print $"(ansi cyan_bold)── ($title) ──(ansi reset)"
    $results | each {|r|
        let mark = if $r.passed {
            $"(ansi green)✓(ansi reset)"
        } else {
            $"(ansi red)✗(ansi reset)"
        }
        print $"  ($mark) ($r.name)"
        if (not $r.passed) and ($r.detail | is-not-empty) {
            print $"    (ansi dark_gray)($r.detail)(ansi reset)"
        }
    } | ignore

    let passed = ($results | where passed | length)
    let total = ($results | length)
    let color = if $passed == $total { "green_bold" } else { "yellow_bold" }
    print $"  (ansi $color)($passed)/($total)(ansi reset)\n"
    $passed == $total
}
