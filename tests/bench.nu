#!/usr/bin/env nu
# tests/bench.nu — Master performance runner
use _lib.nu *

def main [--quick] {
    let suites = [
        { name: "RAM",   script: "ram-bench.nu",  args: (if $quick { ["--quick"] } else { [] }) }
        { name: "Disk",  script: "disk-bench.nu", args: (if $quick { ["--quick"] } else { [] }) }
        { name: "Net",   script: "net-bench.nu",  args: [] }
    ]

    orchestrate "SYSTEM PERFORMANCE BENCHMARK" "magenta_bold" $suites
}

