#!/usr/bin/env bash
#
# Wrapper for SwayOSD Volume Control
# Handles Volume Up/Down and Mute with a 120% limit

case "$1" in
  --up)
    # Raise volume (limit to 120%)
    swayosd-client --output-volume raise --max-volume 120
    ;;
  --down)
    # Lower volume (limit to 120%)
    swayosd-client --output-volume lower --max-volume 120
    ;;
  --mute)
    # Toggle mute
    swayosd-client --output-volume mute-toggle
    ;;
  *)
    echo "Usage: $0 [--up | --down | --mute]"
    exit 1
    ;;
esac
