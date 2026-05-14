#!/usr/bin/env nu
# Verifies the iwd-standalone wireless stack on this host.
# Run:  nu tests/wifi.nu

use _lib.nu *

# ── Discovery ─────────────────────────────────────────────────────────────
# Don't hardcode wlp2s0 / wlan0 — ask iwd for the station-mode device.
def wifi-device []: nothing -> string {
    let r = (^iwctl device list | complete)
    if $r.exit_code != 0 { return "" }

    let candidates = (
        $r.stdout
        | lines
        | where ($it | str contains "station")
        | each {|l| $l | str trim | split row -r '\s+' | get 0 }
    )
    if ($candidates | is-empty) { "" } else { $candidates | first }
}

# Small helper: did `systemctl is-active <unit>` say "active"?
def is-active [unit: string]: nothing -> bool {
    (^systemctl is-active $unit | complete | get stdout | str trim) == "active"
}

# ── Suite: services ───────────────────────────────────────────────────────
def test-services [] {
    [
        (check "iwd.service is active"            (is-active "iwd"))
        (check "systemd-resolved is active"       (is-active "systemd-resolved"))
        (check "NetworkManager NOT active"  (not (is-active "NetworkManager"))  "competing daemon")
        (check "wpa_supplicant NOT active"  (not (is-active "wpa_supplicant"))  "competing daemon")
    ]
}

# ── Suite: D-Bus ownership ────────────────────────────────────────────────
def test-dbus [] {
    let owners = (
        ^busctl list --no-legend
        | complete | get stdout | lines
        | where ($it =~ 'net.connman.iwd|NetworkManager|wpa_supplicant')
    )
    let iwd = ($owners | any {|l| $l | str contains "net.connman.iwd" })
    let nm  = ($owners | any {|l| $l | str contains "NetworkManager" })
    let wpa = ($owners | any {|l| $l | str contains "wpa_supplicant" })

    [
        (check "iwd owns net.connman.iwd"  $iwd        "no D-Bus owner")
        (check "NetworkManager not on bus" (not $nm)   "competing daemon")
        (check "wpa_supplicant not on bus" (not $wpa)  "competing daemon")
    ]
}

# ── Suite: device + connection ────────────────────────────────────────────
def test-device [] {
    let dev = (wifi-device)
    if ($dev | is-empty) {
        return [(fail "station device present" "no station-mode device in iwctl")]
    }

    let show = (^iwctl station $dev show | complete | get stdout)
    let connected = ($show | str contains "connected")

    let known_count = (
        ^iwctl known-networks list
        | complete | get stdout | lines
        | where ($it !~ '^[\s-]*$|Name\s+Security|Known Networks')
        | length
    )

    let addr = (^ip -br addr show $dev | complete)
    let up_with_ip = ($addr.exit_code == 0) and ($addr.stdout | str contains "UP") and ($addr.stdout =~ '\d+\.\d+\.\d+\.\d+')

    [
        (check $"station device detected \(($dev))" true)
        (check "iwctl reports connected"       $connected          $show)
        (check $"($dev) is UP with an IPv4"    $up_with_ip          $addr.stdout)
        (check "at least one known network"    ($known_count > 0)  "no stored profiles")
    ]
}

# ── Suite: dhcpcd not fighting iwd ────────────────────────────────────────
def test-dhcpcd [] {
    let dev = (wifi-device)
    if ($dev | is-empty) { return [] }

    # dhcpcd MUST NOT be holding a lease on the wireless interface.
    let leases = (
        ^ip -br addr show $dev | complete | get stdout
    )
    let has_addr = ($leases =~ '\d+\.\d+\.\d+\.\d+')

    # If dhcpcd is running, confirm it's not listed as managing this iface.
    let dhcpcd_running = (is-active "dhcpcd")
    let conflict = if $dhcpcd_running {
        let st = (^systemctl status dhcpcd --no-pager | complete | get stdout)
        # crude but effective: dhcpcd logs interfaces it manages
        ($st | str contains $dev) and (not ($st =~ $"denyinterfaces.*($dev)"))
    } else { false }

    [
        (check $"($dev) has an IP"          $has_addr  $leases)
        (check "dhcpcd not managing wifi"   (not $conflict)
            $"dhcpcd appears to manage ($dev) — add it to networking.dhcpcd.denyInterfaces")
    ]
}

# ── Suite: reachability ───────────────────────────────────────────────────
def test-reachable [] {
    let ip_ok  = (^ping -c 1 -W 2 1.1.1.1     | complete | get exit_code) == 0
    let dns_ok = (^ping -c 1 -W 3 nixos.org   | complete | get exit_code) == 0
    let resolv = (^resolvectl status | complete | get stdout)
    let dns_pushed = ($resolv | str contains "DNS Servers")

    [
        (check "ICMP to 1.1.1.1"             $ip_ok       "no IP-level reachability")
        (check "DNS resolves nixos.org"      $dns_ok      "name resolution broken")
        (check "resolved has DNS servers"    $dns_pushed  "iwd did not push DNS")
    ]
}

# ── Suite: forwarding / NAT (uplink-sharing setup) ────────────────────────
def test-nat [] {
    let forwarding = ((open /proc/sys/net/ipv4/ip_forward | str trim) == "1")
    let is_root = ((^id -u | complete | get stdout | str trim) == "0")

    let nat_check = if $is_root {
        let r = (^nft list table ip nat | complete)
        check "nft NAT table has masquerade" ($r.stdout | str contains "masquerade") "no masquerade rule"
    } else {
        check "nft NAT inspection (skipped, needs root)" true ""
    }

    [
        (check "IPv4 forwarding enabled" $forwarding "/proc/sys/net/ipv4/ip_forward != 1")
        $nat_check
    ]
}

# ── Runner ────────────────────────────────────────────────────────────────
print $"(ansi blue_bold)wifi stack: iwd standalone(ansi reset)\n"

let all_ok = (
    [
        (report "Services"            (test-services))
        (report "D-Bus ownership"     (test-dbus))
        (report "Device & connection" (test-device))
        (report "dhcpcd boundary"     (test-dhcpcd))
        (report "Reachability"        (test-reachable))
        (report "Forwarding / NAT"    (test-nat))
    ]
    | all {|x| $x }
)

if $all_ok {
    print $"(ansi green_bold)all checks passed(ansi reset)"
    exit 0
} else {
    print $"(ansi yellow_bold)some checks failed — review above(ansi reset)"
    exit 1
}
