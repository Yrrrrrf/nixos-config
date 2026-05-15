#!/usr/bin/env nu
# Test script to verify all setting/toggle commands

print "🛠️ Testing all SET/TOGGLE commands..."
print "--------------------------------"

let bin_dir = ($env.HOME | path join ".local/bin")

let scripts = [
    { name: "Layout",      cmd: $"($bin_dir)/layout --change" },
    { name: "Backlight",   cmd: $"($bin_dir)/kbd-backlight --up" },
    { name: "Performance", cmd: $"($bin_dir)/gpu-performance --change" },
    { name: "Microphone",  cmd: $"($bin_dir)/mic --toggle" },
    { name: "Volume",      cmd: $"($bin_dir)/volume --mute" }
]

for script in $scripts {
    print $"Executing ($script.name)..."
    let output = (do { ^nu -c $script.cmd } | complete)
    if $output.exit_code == 0 {
        print $"($script.name | fill -w 12): ✅ Success"
    } else {
        print $"($script.name | fill -w 12): ❌ [ERROR] ($output.stderr | str trim)"
    }
    sleep 500ms
}
