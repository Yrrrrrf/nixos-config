#!/usr/bin/env nu
# tests/health-disk.nu — SSD health scan
use _lib.nu *

def first-nvme []: nothing -> string {
    let devs = (ls /dev | get name | where ($it =~ "nvme\\dn\\d$"))
    if ($devs | is-empty) { "" } else { $devs | first }
}

def drive-health []: nothing -> any {
    let dev = (first-nvme)
    if ($dev | is-empty) { return {error: "No NVMe device found"} }
    let raw_res = (^sudo smartctl -a -j $dev | complete)
    if $raw_res.exit_code != 0 {
        return { error: $"smartctl failed: ($raw_res.stderr)" }
    }
    let raw = ($raw_res.stdout | from json)
    let log = ($raw | get -o nvme_smart_health_information_log)
    if $log == null { return {error: "No SMART log in output"} }

    # TB written: data_units_written * 512_000 bytes / 1e12
    let tb_written = if ($log | get -o data_units_written | is-not-empty) {
        ($log.data_units_written * 512_000) / 1e12 | math round --precision 2
    } else { 0 }

    {
        # ── Identity ──────────────────────────────────────────────
        device:                    $dev
        model:                     ($raw | get -o model_name)
        firmware:                  ($raw | get -o firmware_version)
        # ── Thermal ───────────────────────────────────────────────
        temp_C:                    ($log | get -o temperature)
        # ── Wear & Endurance ──────────────────────────────────────
        TB_written:                $tb_written
        percent_used:              ($log | get -o percentage_used)
        available_spare_pct:       ($log | get -o available_spare)
        spare_threshold_pct:       ($log | get -o available_spare_threshold)
        # ── Reliability ───────────────────────────────────────────
        power_on_hours:            ($raw | get -o power_on_time | get -o hours)
        unsafe_shutdowns:          ($log | get -o unsafe_shutdowns | default 0)
        media_errors:              ($log | get -o media_errors | default 0)
        error_log_entries:         ($log | get -o num_err_log_entries | default 0)
        controller_busy_time_min:  ($log | get -o controller_busy_time | default 0)
        # ── Status ────────────────────────────────────────────────
        critical_warning:          ($log | get -o critical_warning | default 0)
    }
}

def partition-layout []: nothing -> any {
    let dev = (first-nvme)
    if ($dev | is-empty) { return null }
    let base = ($dev | path basename)  # e.g. nvme0n1
    let res = (^lsblk -J -o NAME,SIZE,FSTYPE,MOUNTPOINT $dev | complete)
    if $res.exit_code != 0 { return null }
    let data = ($res.stdout | from json)
    # Grab children (partitions) of the root device
    let parts = ($data | get -o blockdevices | first | get -o children | default [])
    $parts | select name size fstype mountpoint
}

def main [] {
    if (which smartctl | is-empty) {
        audit "SSD Health" "cyan_bold" { [(skip "SSD health" "smartctl not found")] }
        return
    }

    let h = (drive-health)
    if ($h | get -o error | is-not-empty) {
        audit "SSD Health" "cyan_bold" { [(fail "SSD data" $h.error)] }
        return
    }

    # ── Section 1: SMART data ──────────────────────────────────────
    print $"\n(ansi cyan_bold)━━ SSD Health ━━(ansi reset)"
    $h | table | print
    print ""

    # ── Section 2: Partition layout ────────────────────────────────
    print $"(ansi cyan_bold)━━ Partition Layout ━━(ansi reset)"
    let parts = (partition-layout)
    if $parts != null and ($parts | is-not-empty) {
        $parts | print
    } else {
        print "  (could not read partition layout)"
    }
    print ""

    # ── Section 3: Health checks ───────────────────────────────────
    let spare_ok  = (($h.available_spare_pct | default 0) > ($h.spare_threshold_pct | default 0))
    let media_ok  = ($h.media_errors == 0)
    let warn_ok   = ($h.critical_warning == 0)
    let wear_ok   = (($h.percent_used | default 0) < 90)

    audit "SSD Health" "cyan_bold" {[
        (check "no critical warnings"           $warn_ok  $"critical_warning = ($h.critical_warning)")
        (check "no media errors"                $media_ok $"media_errors = ($h.media_errors)")
        (check "spare headroom above threshold" $spare_ok $"spare ($h.available_spare_pct)% ≤ threshold ($h.spare_threshold_pct)%")
        (check "wear level < 90%"               $wear_ok  $"percent_used = ($h.percent_used)%")
    ]}
}
