#!/usr/bin/env nu
# tests/health-disk.nu — SSD health scan
use _lib.nu *
def first-nvme []: nothing -> string {
    let devs = (ls /dev | get name | where ($it =~ "nvme\\dn\\d$"))
    if ($devs | is-empty) { "" } else {
        $devs | first
    }
}
def drive-health []: nothing -> any {
    let dev = (first-nvme)
    if ($dev | is-empty) { return {error: "No NVMe device found"} }
    let raw_res = (^sudo smartctl -a -j $dev | complete)
    if $raw_res.exit_code != 0 {
        return {
            error: $"smartctl failed: ($raw_res.stderr)"
        }
    }
    let raw = ($raw_res.stdout | from json)
    let log = ($raw | get -o nvme_smart_health_information_log)
    if $log == null { return {error: "No SMART log in output"} }
    {
        device: $dev
        model: ($raw | get -o model_name)
        firmware: ($raw | get -o firmware_version)
        temp_C: ($log | get -o temperature)
        TB_written: (if ($log | get -o data_units_written | is-not-empty) { (($log.data_units_written * 512_000) / 1e12 | math round --precision 2) } else { 0 })
        power_on_hours: ($raw | get -o power_on_time | get -o hours)
        percent_used: ($log | get -o percentage_used)
        critical_warning: ($log | get -o critical_warning | default 0)
    }
}
def main [] {
    if (which smartctl | is-empty) {
        audit "SSD Health" "cyan_bold" { [(skip "SSD health" "smartctl not found")] }
        return
    }
    let h = (drive-health)
    audit "SSD Health" "cyan_bold" {
        if ($h | get -o error | is-not-empty) {
            [(fail "SSD data" $h.error)]
        } else {
            $h | table | print
            print ""
            [(check $"SSD health ($h.device)" ($h.critical_warning == 0) $"Critical Warning: ($h.critical_warning)")]
        }
    }
}
