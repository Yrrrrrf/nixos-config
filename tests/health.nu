#!/usr/bin/env nu
# tests/health.nu — Master health audit runner
use _lib.nu *

def main [] {
    let suites = [
        { name: "RAM",   script: "ram-health.nu" }
        { name: "Disk",  script: "disk-health.nu" }
        { name: "Net",   script: "net-health.nu" }
        { name: "GPU",   script: "gpu-health.nu" }
        { name: "UI",    script: "ui-get.nu" }
    ]

    orchestrate "SYSTEM HEALTH AUDIT" "blue_bold" $suites --silent-success
}

