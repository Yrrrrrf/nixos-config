# _shared.nu — Generic helpers for waybar-facing scripts.
# Resolved at runtime from ~/.local/bin/ where every executable lands,
# so g14 scripts import this identically to desktop scripts.
# Build a compact JSON record for waybar.
# Convention: { text, tooltip, class } — each carries DIFFERENT information.
#   text    = bar display (icon + minimal state)
#   tooltip = expansion (description, available actions — NOT a restatement)
#   class   = CSS hook (lowercase state token)
export def as_json [data: record]: nothing -> string {
    $data | to json -r
}
# Send a desktop notification.
# title = the config being changed     ("Power Profile")
# body  = the change itself            ("Switched to Performance")
# replace-id is derived from the title hash so same-category notifications
# overwrite each other instead of stacking with a count.
export def notify [title: string, body: string] {
    let id = (
        $title | hash sha256 | str substring 0..6 | into int --radix 16
    )
    notify-send --replace-id $id --urgency low $title $body
}
# Run an external command, return its stdout trimmed.
# Stderr is captured and discarded — critical for asusctl which spams
# zbus tracing INFO logs even on successful invocations.
export def capture [code: closure]: nothing -> string {
    (do $code | complete).stdout | str trim
}
# Run a closure, discard everything (stdout + stderr + exit code).
# Used for fire-and-forget setters (swayosd-client, asusctl --set).
export def run_silent [code: closure] {
    do $code | complete | ignore
}
# pct + three icons -> {icon, class}. Buckets: >66 high, >33 medium, else low.
export def level3 [pct: int, high: string, med: string, low: string]: nothing -> record {
    if $pct > 66 { {icon: $high, class: "high"} }
    else if $pct > 33 { {icon: $med, class: "medium"} }
    else { {icon: $low, class: "low"} }
}
# Emit a waybar-JSON status line.
export def status [text: string, tooltip: string, class: string]: nothing -> string {
    as_json { text: $text, tooltip: $tooltip, class: $class }
}
# Custom OSD message + icon, optional progress bar (0.0..1.0). Fire-and-forget.
export def osd [message: string, icon: string, --progress: float] {
    let args = ([--custom-message $message --custom-icon $icon]
        | append (if $progress != null { [--custom-progress $progress] } else { [] }))
    run_silent { swayosd-client ...$args }
}
