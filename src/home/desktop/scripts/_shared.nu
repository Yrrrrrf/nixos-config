# _shared.nu
# Shared utilities for desktop management scripts

# Standardized notification helper
export def notify [title: string, msg: string, --icon: string, --tag: string] {
    let icon_arg = if ($icon | is-empty) { [] } else { ["-i" $icon] }
    let tag_arg = if ($tag | is-empty) { [] } else { ["-h" $"string:x-dunst-stack-tag:($tag)"] }
    ^notify-send ...$icon_arg ...$tag_arg $title $msg
}

# Standardized Waybar JSON output
export def as_json [data: record] {
    $data | to json --raw | print
}

# Standardized console logging
export def log_success [msg: string] {
    print $msg
}

# Run a command silently (swallowing both stdout and stderr)
export def run_silent [code: closure] {
    do $code | complete | ignore
}

