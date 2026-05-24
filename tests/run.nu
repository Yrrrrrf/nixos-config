#!/usr/bin/env nu
# tests/run.nu — Umbrella test runner.
#
# Usage (from repo root):
#   nu tests/run.nu              # non-destructive: get suite only
#   nu tests/run.nu --all        # get + set suites (destructive)
#   nu tests/run.nu --set-only   # action verbs only (destructive)
#
# Exit code: 0 = all pass, 1 = any fail.

def run_get []: nothing -> bool {
    (nu tests/get.nu | complete).exit_code == 0
}

def run_set []: nothing -> bool {
    (nu tests/set.nu | complete).exit_code == 0
}

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
