# _shared.nu — Generic helpers shared across all waybar-facing scripts.
# Imported via `use _shared.nu *` from sibling scripts AND from g14
# scripts (they resolve here at runtime because every executable lands
# in the same ~/.local/bin/ directory).

# Build a compact JSON payload for waybar consumption.
#
# Convention enforced by waybar.jsonc:
#   `"format": "{}"`        → renders the `text` field literally
#   `tooltip` present       → waybar auto-detects, no need for "tooltip": true
#   `class` present         → becomes a CSS hook in waybar-style.css
#
# Example:
#   as_json { text: "🚀 Performance", tooltip: "Power profile: Performance", class: "performance" }
export def as_json [data: record] {
    $data | to json -r
}

# Fire a desktop notification through dunst.
# Single entry point for all script notifications. Low urgency by default
# so the user can mash volume keys without flooding the screen.
export def log_success [msg: string] {
    notify-send --urgency low --app-name "scripts" "✓" $msg
}

# Execute a closure with stdout+stderr suppressed.
# Used to wrap external commands (asusctl, swayosd-client, hyprctl,
# wpctl) so their chatter doesn't leak into waybar's `exec` capture
# or interactive shell output.
export def run_silent [code: closure] {
    do $code | complete | ignore
}
