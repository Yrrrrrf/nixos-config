# _asus.nu
# ASUS-specific helpers + locally-bundled copies of the generic helpers.
# TODO(dedup): set NU_LIB_DIRS in nushell.nix to include both script dirs,
# then replace the bundled helpers below with `use _shared.nu *`.
# Until then, keep these 4 functions in sync with _shared.nu manually:
#   diff src/home/desktop/scripts/_shared.nu src/host/g14/scripts/_asus.nu

# Bundled (not imported) because nushell's `use` resolves relative to the
# script's directory, and these scripts live in a different folder than
# src/home/desktop/scripts/_shared.nu.

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

# Robust asusctl output parsing (handles ANSI, log noise, and various separators)
export def parse_asus [cmd_output: string, search_pattern: string] {
    let line = ($cmd_output
        | lines
        | find $search_pattern
        | first
        | ansi strip)

    if ($line | str contains ":") {
        $line | split row ":" | last | str trim
    } else {
        # Fallback for "Active profile is Quiet" style outputs
        $line | split row " " | last | str trim
    }
}
