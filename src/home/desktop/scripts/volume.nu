#!/usr/bin/env nu

# Wrapper for SwayOSD Volume Control
# Handles Volume Up/Down and Mute with a 120% limit

def main [
    --up    # Raise volume
    --down  # Lower volume
    --mute  # Toggle mute
] {
    if $up {
        swayosd-client --output-volume raise --max-volume 120
    } else if $down {
        swayosd-client --output-volume lower --max-volume 120
    } else if $mute {
        swayosd-client --output-volume mute-toggle
    }
}
