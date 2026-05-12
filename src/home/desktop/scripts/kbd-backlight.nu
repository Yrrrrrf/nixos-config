#!/usr/bin/env nu
use _shared.nu *

# Keyboard Backlight Manager
const levels = ["Off", "Low", "Med", "High"]

def get_current_level [] {
    parse_asus (asusctl -k) "Current keyboard led brightness:"
}

def set_brightness [level: string] {
    run_silent { asusctl --kbd-bright ($level | str downcase) }
}



def main [
    --up   # Increase brightness
    --down # Decrease brightness
    --get  # Get current level for Waybar
] {
    let current_level = (get_current_level)
    
    if $get {
        waybar_json { level: $current_level, icon: "󰌌" }
        return
    }

    let current_index = ($levels | enumerate | where item == $current_level | get 0?.index | default (-1))

    if $current_index == -1 {
        print -e $"Error: Could not determine current backlight level. Got: ($current_level)"
        exit 1
    }

    if $up {
        if $current_index < (($levels | length) - 1) {
            let next = ($levels | get ($current_index + 1))
            set_brightness $next
            log_success $"Keyboard backlight increased to: ($next)"
        }
    } else if $down {
        if $current_index > 0 {
            let next = ($levels | get ($current_index - 1))
            set_brightness $next
            log_success $"Keyboard backlight decreased to: ($next)"
        }
    }
}


