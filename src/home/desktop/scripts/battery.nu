#!/usr/bin/env nu
# battery.nu — Battery status monitor + swayosd status display.
# Reads sysfs battery data, classifies level (green >30%, yellow >10%, red <=10%),
# and provides Waybar JSON output and SwayOSD popups.
use _shared.nu *
# Detect primary battery path from sysfs
def battery_dir []: nothing -> string {
    if ('/sys/class/power_supply/BAT0' | path exists) {
        '/sys/class/power_supply/BAT0'
    } else if ('/sys/class/power_supply/BAT1' | path exists) {
        '/sys/class/power_supply/BAT1'
    } else {
        ""
    }
}
# Read battery state (capacity %, charging status, power rate)
def battery_info []: nothing -> record {
    let dir = (battery_dir)
    if $dir == "" {
        return {
            pct: 100
            charging: false
            status: "Unknown"
            power_w: 0.0
        }
    }
    let pct_raw = (capture { cat $"($dir)/capacity" })
    let pct = (try {
        $pct_raw | into int
    } catch { 100 })
    let status_raw = (capture { cat $"($dir)/status" })
    let status_str = if ($status_raw | is-empty) { "Discharging" } else { $status_raw }
    let charging = ($status_str == "Charging" or $status_str == "Full")
    # Read power draw in Watts if available (power_now is in microwatts)
    let power_raw = (capture { cat $"($dir)/power_now" })
    let power_w = (try {
        let uW = ($power_raw | into float)
        ($uW / 1000000.0 | math round --precision 1)
    } catch { 0.0 })
    {
        pct: $pct
        charging: $charging
        status: $status_str
        power_w: $power_w
    }
}
# Select icon and level classification (Green >30%, Yellow >10%, Red <=10%)
def meta [pct: int, charging: bool, power_w: float]: nothing -> record {
    let icon = if $charging {
        if $pct > 90 { "󰂋" } else if $pct > 70 { "󰂊" } else if $pct > 50 { "󰂉" } else if $pct > 30 { "󰂈" } else if $pct > 10 { "󰂇" } else { "󰢜" }
    } else {
        if $pct > 90 { "󰁹" } else if $pct > 70 { "󰂁" } else if $pct > 50 { "󰁿" } else if $pct > 30 { "󰁽" } else if $pct > 10 { "󰁻" } else { "󰂎" }
    }
    let level_name = if $charging {
        "Charging"
    } else if $pct > 30 {
        "Good"
    } else if $pct > 10 {
        "Warning"
    } else {
        "Critical"
    }
    let p_info = if $power_w > 0.0 { $" (($power_w)W)" } else { "" }
    let desc = $"Battery ($pct)% — ($level_name)($p_info)"
    {
        icon: $icon
        level_name: $level_name
        desc: $desc
    }
}
# Display OSD pop-up using shared `osd` function
def show_osd [pct: int, icon: string, level_name: string] {
    let progress = ($pct | into float) / 100.0
    osd $"($pct)%" $icon --progress $progress
}
# Main CLI entrypoint
def main [
    --get   # Output JSON status for Waybar
    --show  # Trigger SwayOSD notification
]: nothing -> nothing {
    let info = (battery_info)
    let m = (meta $info.pct $info.charging $info.power_w)
    if $show {
        show_osd $info.pct $m.icon $m.level_name
    } else if $get {
        status $"($m.icon) ($info.pct)%" $m.desc
    } else {
        show_osd $info.pct $m.icon $m.level_name
        status $"($m.icon) ($info.pct)%" $m.desc
    }
}
