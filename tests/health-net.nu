#!/usr/bin/env nu
# tests/health-net.nu — Network stack health scan
use _lib.nu *

def is-active [unit: string]: nothing -> bool {
    (^systemctl is-active $unit | complete | get stdout | str trim) == "active"
}

def wifi-device []: nothing -> string {
    let r = (^iwctl device list | complete)
    if $r.exit_code != 0 { return "" }
    let candidates = ($r.stdout | lines | where ($it =~ "station") | each {|l| $l | str trim | split row -r "\\s+" | get 0 })
    if ($candidates | is-empty) { "" } else { $candidates | first }
}

def main [] {
    audit "Network Stack" "cyan_bold" {
        let services = [
            (check "iwd.service active" (is-active "iwd"))
            (check "systemd-resolved active" (is-active "systemd-resolved"))
            (check "NM inactive" (not (is-active "NetworkManager")))
        ]
        
        let dev = (wifi-device)
        let device_res = if ($dev | is-empty) {
            [(fail "WiFi device" "no station device found")]
        } else {
            [(pass $"WiFi device detected ($dev)") 
             (check_grep "iwctl connected" "iwctl" ["station" $dev "show"] "connected")]
        }
        
        let reach = [
            (check_exec "Ping 1.1.1.1" "ping" ["-c" "1" "-W" "2" "1.1.1.1"])
            (check_exec "DNS nixos.org" "ping" ["-c" "1" "-W" "3" "nixos.org"])
        ]
        
        [ $services $device_res $reach ] | flatten
    }
}
