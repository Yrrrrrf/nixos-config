#!/usr/bin/env nu
# Test script to verify all --get outputs for Waybar

print "🔍 Testing all GET commands..."
print "--------------------------------"

let bin_dir = ($env.HOME | path join ".local/bin")

let scripts = [
    { name: "Layout",      cmd: $"($bin_dir)/layout --get" },
    { name: "Backlight",   cmd: $"($bin_dir)/kbd-backlight --get" },
    { name: "Performance", cmd: $"($bin_dir)/gpu-performance --get" },
    { name: "Microphone",  cmd: $"($bin_dir)/mic --get-status" },
    { name: "Volume",      cmd: $"($bin_dir)/volume --get" }
]

for script in $scripts {
    let output = (do { ^nu -c $script.cmd } | complete)
    if $output.exit_code == 0 {
        print $"($script.name | fill -w 12): ($output.stdout | str trim)"
    } else {
        print $"($script.name | fill -w 12): [ERROR] ($output.stderr | str trim)"
    }
}
