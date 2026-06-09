#!/usr/bin/env nu
# tests/bench-ram.nu — RAM userspace triage (triage-bench)
use _lib.nu *
const DEFAULT_FRACTION = 0.5
const QUICK_CAP_MIB = 1024
def free-ram-mib []: nothing -> int {
    open /proc/meminfo | parse --regex '(?P<key>\w+):\s+(?P<value>\d+)\s+kB' | where key == "MemAvailable" | get 0.value | into int | $in / 1024 | math floor | into int
}
def run-memtester [size_mb: int, loops: int] {
    let r = (^sudo memtester $"($size_mb)M" $loops | complete)
    let stdout_lower = ($r.stdout | str downcase)
    let mlock_failed = ($stdout_lower | str contains "failed: cannot allocate")
    let failures = ($r.stdout | str contains "FAILURE")
    if $mlock_failed {
        return (fail "memtester mlock" "could not mlock — test invalid")
    }
    if $failures or $r.exit_code != 0 {
        return (fail "memtester health" $"found failures or exit code ($r.exit_code)")
    }
    pass "memtester clean"
}
def main [--quick] {
    section "RAM Userspace Bench (memtester)"
    let auto_size = ((free-ram-mib) * $DEFAULT_FRACTION | math floor | into int)
    let size = if $quick {
        [$auto_size, $QUICK_CAP_MIB] | math min
    } else { $auto_size }
    let loops = if $quick { 1 } else { 2 }
    let mt_res = (run-memtester $size $loops)
    let mt_label = ([
        "memtester \("
        ($size | into string)
        "M x "
        ($loops | into string)
        "\)"
    ] | str join)
    report "RAM benchmark" [$mt_res]
}
