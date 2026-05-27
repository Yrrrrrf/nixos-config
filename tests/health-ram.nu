#!/usr/bin/env nu
# tests/health-ram.nu — RAM health scan
use _lib.nu *
def test-kernel [] { [
    (check_grep "no MCE detected" "sudo" ["dmesg"] "mce:|machine check|hardware error|corrected error" true)
    (check_grep "no recent segfaults" "sudo" ["journalctl", "--since", "30 days ago", "--no-pager"] "segfault" true)
    (check_grep "no OOM kills" "sudo" ["journalctl", "--since", "30 days ago", "--no-pager"] "oom-killer|killed process" true)
] }
def main [] { audit "RAM Health" "cyan_bold" { test-kernel } }
