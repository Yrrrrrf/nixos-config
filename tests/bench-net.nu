#!/usr/bin/env nu
# tests/bench-net.nu — Network performance benchmarking
use _lib.nu *
def first-wifi-iface []: nothing -> string {
    let raw = (^iw dev | lines | each { str trim })
    $raw | where ($it | str starts-with "Interface ") | first | parse "Interface {iface}" | get iface.0
}
def ping-stats [target: string, count: int]: nothing -> record {
    let r = (^ping -c $count -i 0.2 -q $target | complete)
    if $r.exit_code != 0 { return {error: "ping failed"} }
    let stats_line = ($r.stdout | lines | where ($it | str contains "min/avg/max"))
    let nums = (
        $stats_line | get 0 | split row "=" | get 1 | str replace " ms" "" | str trim | split row "/" | each { into float }
    )
    {
        min: ($nums | get 0)
        avg: ($nums | get 1)
        max: ($nums | get 2)
        jitter: ($nums | get 3)
    }
}
def main [--iperf: string, --quick] {
    let iface = (first-wifi-iface)
    section "Network Performance (ping)"
    let p = (ping-stats "1.1.1.1" 20)
    $p | print
    if not ($iperf | is-empty) {
        print $"\n"
        section $"iperf3 Throughput vs \(($iperf)\)"
        let r = (^iperf3 -c $iperf -t 5 -J | from json)
        {
            upload_mbps: (($r.end.sum_sent.bits_per_second / 1e6) | math round)
            download_mbps: (($r.end.sum_received.bits_per_second / 1e6) | math round)
        } | print
    }
}
