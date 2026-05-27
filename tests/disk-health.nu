#!/usr/bin/env nu
# tests/disk-health.nu — SSD health scan
use _lib.nu *

def first-nvme []: nothing -> string {
    ls /dev | get name | where ($it =~ "nvme\\dn\\d$") | first
}

def drive-health []: nothing -> record {
    let dev = (first-nvme)
    let raw = (^sudo smartctl -a -j $dev | from json)
    let log = $raw.nvme_smart_health_information_log
    {
        device:         $dev
        model:          $raw.model_name
        firmware:       $raw.firmware_version
        temp_C:         $log.temperature
        TB_written:     (($log.data_units_written * 512_000) / 1e12 | math round --precision 2)
        power_on_hours: $raw.power_on_time.hours
        percent_used:   $log.percentage_used
        critical_warning: $log.critical_warning
    }
}

def main [] {
    if (which smartctl | is-empty) {
        print $"(ansi red)smartctl not found.(ansi reset)"
        exit 1
    }

    let h = (drive-health)
    
    audit "SSD Health" "cyan_bold" {
        $h | print
        print ""
        [(check $"SSD health ($h.device)" ($h.critical_warning == 0) $"Critical Warning: ($h.critical_warning)")]
    }
}
