# _lib.nu — Shared helpers for nu test suites.
# Each test returns: { name: string, passed: bool, detail: string }

export def pass [name: string] {
    { name: $name, passed: true, detail: "" }
}

export def fail [name: string, detail: string = ""] {
    { name: $name, passed: false, detail: $detail }
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
    let passed = ($results | where passed | length)
    let total  = ($results | length)
    let ok     = $passed == $total

    let header_color = if $ok { "green_bold" } else { "red_bold" }
    print $"(ansi $header_color)── ($title)(ansi reset)  (ansi dark_gray)($passed)/($total)(ansi reset)"

    $results | each {|r|
        if $r.passed {
            print $"  (ansi green)✓(ansi reset) ($r.name)"
        } else {
            print $"  (ansi red)✗(ansi reset) (ansi red)($r.name)(ansi reset)"
            if ($r.detail | is-not-empty) {
                # wrap long detail lines at ~90 chars
                $r.detail | split row "\n" | each {|line|
                    print $"    (ansi dark_gray)($line)(ansi reset)"
                } | ignore
            }
        }
    } | ignore

    print ""
    $ok
}
