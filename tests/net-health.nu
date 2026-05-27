#!/usr/bin/env nu
# tests/net-health.nu — Network stack health scan
use _lib.nu *

def is-active [unit: string]: nothing -> bool {
    (^systemctl is-active  | complete | get stdout | str trim) == "active"
}

def wifi-device []: nothing -> string {
    let r = (^iwctl device list | complete)
    if .exit_code != 0 { return "" }
    let candidates = (.stdout | lines | where ( | str contains "station") | each {|l|  | str trim | split row -r "\\s+" | get 0 })
    if ( | is-empty) { "" } else {  | first }
}

def main [] {
    audit "Network Stack" "cyan_bold" {
        let services = [
            (check "iwd.service active" (is-active "iwd"))
            (check "systemd-resolved active" (is-active "systemd-resolved"))
            (check "NM inactive" (not (is-active "NetworkManager")))
        ]
        
        let dev = (wifi-device)
        let device_res = if ( | is-empty) {
            [(fail "WiFi device" "no station device found")]
        } else {
            [(pass $"WiFi device detected ()") 
             (check_grep "iwctl connected" "iwctl" ["station"  "show"] "connected")]
        }
        
        let reach = [
            (check_exec "Ping 1.1.1.1" "ping" ["-c" "1" "-W" "2" "1.1.1.1"])
            (check_exec "DNS nixos.org" "ping" ["-c" "1" "-W" "3" "nixos.org"])
        ]
        
        [  ]
    }
}
