# Waybar Scripts v2 — Refactor TODO

The v1 refactor fixed the **waybar contract** but shipped mediocre script internals: brittle parsers, redundant output fields, stacking notifications, and a `pick_icon` that returned the same glyph for every state. This pass fixes all of that.

The breakthrough is the `asusctl profile -p` output you captured. The active profile lives on the **first** matching line, not the last whitespace token of the whole blob — and the rest is stderr spam from zbus tracing. Once we parse properly and route stderr to `/dev/null`, gpu-performance becomes trivial. Same lesson applies everywhere else.

---

## What's actually changing

| Concern | v1 (broken) | v2 (this pass) |
|---|---|---|
| asusctl parsing | `\| split row " " \| last` | `lines \| where "Active profile is" \| parse` |
| stderr spam | leaks through | captured + discarded via `capture` helper |
| Redundant output | text/tooltip/class all carry the profile name | text=icon+state, tooltip=**description**, class=state |
| Layout verbosity | `english-us` or worse | `US`, `MX` — country code only |
| Notifications | `✓ <msg>`, stack with counter | `<Category>` title + `<change>` body, replace by category |
| `pick_icon` | one glyph repeated 5 times | dropped; `meta` returns icon+description in one shot |
| Tests | spawn `^nu -c`, dump stdout, no assertions | call binaries directly, parse JSON, assert contract |

---

## 1. `_shared.nu` — new helpers

Replace the file. Three changes: `notify` now uses `--replace-id` derived from the title hash (so same-category notifications replace instead of stacking), `capture` is new (runs a closure and returns just stdout, swallowing stderr), `log_success` is **gone** (the `✓` was noise).

```nu
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
    let id = ($title | hash sha256 | str substring 0..6 | into int --radix 16)
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
```

---

## 2. `gpu-performance.nu` — proper asusctl parsing

```nu
#!/usr/bin/env nu
# gpu-performance.nu — ASUS power profile (G14).
# Reads asusctl's "Active profile is X" line, ignoring stderr spam.
use _shared.nu *

# asusctl profile -p outputs (after stderr filter):
#   Active profile is Performance
#   Profile on AC is Performance
#   Profile on Battery is Quiet
# Only the first line carries the active profile.
def current []: nothing -> string {
    capture { asusctl profile -p }
    | lines
    | where {|l| $l | str starts-with "Active profile is"}
    | get 0?
    | default ""
    | parse "Active profile is {p}"
    | get p.0?
    | default "Unknown"
}

# Single source of truth: profile name → presentation record.
# tooltip carries the *description*, not a restatement of `text`.
def meta [profile: string]: nothing -> record {
    match $profile {
        "Quiet"       => { icon: "󰒲", desc: "Silent — fans off, battery priority" }
        "Balanced"    => { icon: "󰓅", desc: "Default — adaptive performance" }
        "Performance" => { icon: "󱐌", desc: "Maximum — fans engaged, plugged in recommended" }
        _             => { icon: "󰋖", desc: "Unknown profile state" }
    }
}

def main [--get --change] {
    if $change {
        run_silent { asusctl profile -n }
        let now = (current)
        notify "Power Profile" $"Switched to ($now)"
    } else {
        let now = (current)
        let m = (meta $now)
        as_json {
            text:    $"($m.icon) ($now)"
            tooltip: $m.desc
            class:   ($now | str downcase)
        }
    }
}
```

**What's different:** `capture` swallows the zbus tracing. The parse grabs the right line by prefix match instead of the wrong line by trailing token. `meta` returns icon + description together so the redundancy is structural — there's nowhere left to repeat the profile name. The tooltip describes *what the profile does*, not what it's called.

---

## 3. `kbd-backlight.nu` — read sysfs, set via asusctl

The current value lives in the kernel: `/sys/class/leds/asus::kbd_backlight/brightness` (0..3). Reading there avoids parsing asusctl text entirely. Setting still goes through `asusctl --kbd-bright` because that path is permission-aware.

```nu
#!/usr/bin/env nu
# kbd-backlight.nu — ASUS keyboard backlight cycling (G14).
# Reads kernel sysfs; writes via asusctl daemon path.
use _shared.nu *

const SYS_PATH = "/sys/class/leds/asus::kbd_backlight/brightness"
const LEVELS = ["off" "low" "med" "high"]

# Current level as integer 0..3. sysfs is single source of truth.
def current []: nothing -> int {
    try { open $SYS_PATH | str trim | into int } catch { 0 }
}

# Compute next level name (clamped, no wrap).
def step [direction: string]: nothing -> string {
    let now = (current)
    let next_idx = (match $direction {
        "up"   => (($now + 1) | math min 3)
        "down" => (($now - 1) | math max 0)
        _      => $now
    })
    $LEVELS | get $next_idx
}

# Level int → presentation record. Different icons per level so the
# bar visually reflects state, not a static glyph.
def meta [level: int]: nothing -> record {
    match $level {
        0 => { icon: "󰌌", desc: "Backlight off" }
        1 => { icon: "󱨇", desc: "Backlight low" }
        2 => { icon: "󱨈", desc: "Backlight medium" }
        3 => { icon: "󱨉", desc: "Backlight high" }
        _ => { icon: "󰋖", desc: "Backlight unknown" }
    }
}

def main [--get --up --down] {
    let dir = if $up { "up" } else if $down { "down" } else { null }

    if $dir != null {
        let target = (step $dir)
        run_silent { asusctl --kbd-bright $target }
        notify "Keyboard Backlight" $"Set to ($target)"
    } else {
        let lvl = (current)
        let m = (meta $lvl)
        as_json {
            text:    $m.icon
            tooltip: $m.desc
            class:   ($LEVELS | get $lvl)
        }
    }
}
```

**What's different:** state comes from sysfs (single byte file, no parsing). `step` does the arithmetic on the integer; `meta` maps the integer to icon+description. text is JUST the icon (compact bar), tooltip is the actual state description, class is the state token. Three fields, three different jobs.

---

## 4. `layout.nu` — country code only

Strip everything except the country. `English (US, intl., with dead keys)` → `US`. `Spanish (Mexico)` → `MX`. Extend the `country` function when a new layout joins the rotation.

```nu
#!/usr/bin/env nu
# layout.nu — Keyboard layout switcher (Hyprland).
# Bar shows country code only; tooltip carries the full keymap name.
use _shared.nu *

const KEYBOARD_NAME = "at-translated-set-2-keyboard"

# Active keymap name from hyprctl.
def keymap []: nothing -> string {
    hyprctl devices -j
    | from json
    | get keyboards
    | where name == $KEYBOARD_NAME
    | get 0?.active_keymap
    | default "Unknown"
}

# Reduce keymap names to country codes.
# Fast path: 2 uppercase letters right after first "(", e.g. "(US".
# Fallback: known country names mapped to ISO-ish codes.
# Add new entries here as new layouts join the rotation.
def country [name: string]: nothing -> string {
    let direct = ($name | parse -r '\((?P<c>[A-Z]{2})' | get c.0?)
    if $direct != null { return $direct }

    let inside = ($name | parse -r '\((?P<v>[^,)]+)' | get v.0? | default "" | str trim)
    {
        "Mexico":          "MX"
        "Latin American":  "LA"
        "United Kingdom":  "UK"
    } | get -i $inside | default "??"
}

def main [--get --change] {
    if $change {
        run_silent { hyprctl switchxkblayout $KEYBOARD_NAME next }
        let now = (keymap)
        notify "Keyboard Layout" (country $now)
    } else {
        let now = (keymap)
        let code = (country $now)
        as_json {
            text:    $"⌨ ($code)"
            tooltip: $now              # full keymap name lives here, not in bar
            class:   ($code | str downcase)
        }
    }
}
```

**What's different:** `text` is `⌨ US` / `⌨ MX` — clean, two characters of identity. The verbose `English (US, intl., with dead keys)` lives in the tooltip where verbosity is welcome. The notification just says `Keyboard Layout` / `US`. No more spam in the bar.

---

## 5. `volume.nu` — slim it down

```nu
#!/usr/bin/env nu
# volume.nu — Audio sink control + waybar status.
use _shared.nu *

# wpctl prints: "Volume: 0.50" or "Volume: 0.50 [MUTED]"
def state []: nothing -> record {
    let raw = (capture { wpctl get-volume @DEFAULT_AUDIO_SINK@ })
    let muted = ($raw | str contains "MUTED")
    let pct = (
        $raw
        | parse -r 'Volume: (?P<v>[0-9.]+)'
        | get v.0
        | into float
        | $in * 100
        | math round
        | into int
    )
    { pct: $pct, muted: $muted }
}

# (pct, muted) → presentation. tooltip = action hint, not a number restated.
def meta [pct: int, muted: bool]: nothing -> record {
    if $muted {
        { icon: "󰝟", desc: "Muted — click to unmute", class: "muted" }
    } else {
        let icon = if $pct > 66 { "󰕾" } else if $pct > 33 { "󰖀" } else { "󰕿" }
        let class = if $pct > 66 { "high" } else if $pct > 33 { "medium" } else { "low" }
        { icon: $icon, desc: "Scroll to adjust, click to mute", class: $class }
    }
}

def main [--get --up --down --mute] {
    if    $up   { run_silent { swayosd-client --output-volume raise } }
    else if $down { run_silent { swayosd-client --output-volume lower } }
    else if $mute { run_silent { swayosd-client --output-volume mute-toggle } }
    else {
        let s = (state)
        let m = (meta $s.pct $s.muted)
        as_json {
            text:    $"($m.icon) ($s.pct)%"
            tooltip: $m.desc
            class:   $m.class
        }
    }
}
```

**What's different:** action verbs delegate to swayosd-client (which renders its own OSD — no notification needed). Tooltip is an *action hint*, not a number restated. `meta` returns icon+desc+class together.

---

## 6. `mic.nu` — same pattern

```nu
#!/usr/bin/env nu
# mic.nu — Microphone mute toggle + waybar status.
use _shared.nu *

def muted []: nothing -> bool {
    capture { wpctl get-volume @DEFAULT_AUDIO_SOURCE@ } | str contains "MUTED"
}

def meta [is_muted: bool]: nothing -> record {
    if $is_muted {
        { icon: "󰍭", desc: "Microphone muted",  class: "muted" }
    } else {
        { icon: "󰍬", desc: "Microphone active", class: "active" }
    }
}

def main [--get-status --toggle] {
    if $toggle {
        run_silent { wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle }
        let m = (meta (muted))
        notify "Microphone" $m.desc
    } else {
        let m = (meta (muted))
        as_json {
            text:    $m.icon
            tooltip: $m.desc
            class:   $m.class
        }
    }
}
```

**What's different:** `meta` is reused between the toggle path (for notification body) and the `--get-status` path (for the bar). One state-to-presentation function, two consumers. Text is JUST the icon — compact. The toggle notification body comes from the same `meta.desc` field, so changing the wording is one edit.

---

## 7. `brightness.nu` — same pattern, vendor-agnostic

```nu
#!/usr/bin/env nu
# brightness.nu — Screen backlight control + waybar status.
# brightnessctl for state, swayosd-client for OSD.
use _shared.nu *

def percent []: nothing -> int {
    let cur = (capture { brightnessctl get } | into int)
    let max = (capture { brightnessctl max } | into int)
    (($cur * 100) / $max | math round | into int)
}

def meta [pct: int]: nothing -> record {
    let icon = if $pct > 66 { "󰃠" } else if $pct > 33 { "󰃟" } else { "󰃞" }
    let class = if $pct > 66 { "high" } else if $pct > 33 { "medium" } else { "low" }
    { icon: $icon, desc: "Scroll to adjust", class: $class }
}

def main [--get --up --down] {
    if    $up   { run_silent { swayosd-client --brightness raise } }
    else if $down { run_silent { swayosd-client --brightness lower } }
    else {
        let p = (percent)
        let m = (meta $p)
        as_json {
            text:    $"($m.icon) ($p)%"
            tooltip: $m.desc
            class:   $m.class
        }
    }
}
```

---

## 8. `powermenu.nu` — unchanged shape, smaller comment

```nu
#!/usr/bin/env nu
# powermenu.nu — Session/power actions.
# No args = walker picker. With arg = dispatch directly.
use _shared.nu *

def pick []: nothing -> string {
    "Logout\nSuspend\nReboot\nShutdown"
    | walker --dmenu --prompt "Power:"
    | str trim
}

def dispatch [action: string] {
    match $action {
        "Logout"   => { run_silent { hyprctl dispatch exit } }
        "Suspend"  => { run_silent { systemctl suspend } }
        "Reboot"   => { run_silent { systemctl reboot } }
        "Shutdown" => { run_silent { systemctl poweroff } }
        _          => { }
    }
}

def main [action?: string] {
    let chosen = (if ($action | is-empty) { pick } else { $action })
    if not ($chosen | is-empty) { dispatch $chosen }
}
```

---

## 9. `screenshot.nu` — restructured notifications

Title = "Screenshot", body = the actual action/result.

```nu
#!/usr/bin/env nu
# screenshot.nu — Capture region or full screen via hyprshot.
use _shared.nu *

def main [--region --screen] {
    if $region {
        notify "Screenshot" "Select a region to capture"
        run_silent { hyprshot -m region }
    } else if $screen {
        run_silent { hyprshot -m output }
        notify "Screenshot" "Full screen saved"
    }
}
```

---

## 10. Tests — `tests/_lib.nu` (small additions)

Keep the existing file. Two additions for the new test scripts:

```nu
# Add to existing _lib.nu

# Parse JSON safely. Returns null on failure (no exception leaks).
export def try_json [text: string]: nothing -> any {
    try { $text | from json } catch { null }
}

# Check a record has all required keys with non-empty values.
# Returns null if OK, error string if not. Designed to be `compact`-ed in lists.
export def field_issues [rec: record, required: list]: nothing -> list {
    $required | each {|f|
        let v = ($rec | get -i $f)
        if $v == null            { $"missing ($f)" }
        else if ($v | is-empty)  { $"empty ($f)" }
        else                     { null }
    } | compact
}
```

---

## 11. Tests — `tests/get.nu` (rewritten)

Calls binaries directly (no `^nu -c` subshell overhead), parses JSON, asserts the waybar contract `{text, tooltip, class}` is satisfied.

```nu
#!/usr/bin/env nu
# tests/get.nu — Verify every script's --get satisfies the waybar JSON contract.
# Usage:
#   nu tests/get.nu              # all scripts
#   nu tests/get.nu volume       # one script
use _lib.nu *

const REQUIRED = ["text" "tooltip" "class"]

# Each entry: name + closure that invokes the binary.
# Closures defer execution so we can filter & dispatch generically.
const CASES = [
    { name: "volume",          run: { ^volume --get } }
    { name: "mic",             run: { ^mic --get-status } }
    { name: "brightness",      run: { ^brightness --get } }
    { name: "layout",          run: { ^layout --get } }
    { name: "gpu-performance", run: { ^gpu-performance --get } }
    { name: "kbd-backlight",   run: { ^kbd-backlight --get } }
]

# Run one case, return a result record for `report`.
def check_case [c: record]: nothing -> record {
    let out = (do $c.run | complete)

    if $out.exit_code != 0 {
        return (fail $c.name $"exit ($out.exit_code): ($out.stderr | str trim | str substring 0..80)")
    }

    let json = (try_json $out.stdout)
    if $json == null {
        return (fail $c.name $"stdout not valid JSON: ($out.stdout | str substring 0..60)")
    }

    let issues = (field_issues $json $REQUIRED)
    if ($issues | is-empty) { pass $c.name } else { fail $c.name ($issues | str join "; ") }
}

def main [filter?: string] {
    let cases = (
        if ($filter | is-empty) { $CASES }
        else { $CASES | where name == $filter }
    )

    if ($cases | is-empty) {
        print $"(ansi red)No case matches '($filter)'(ansi reset)"
        print $"Available: ($CASES | get name | str join ', ')"
        return
    }

    let results = ($cases | each { check_case $in })
    report "Waybar --get contracts" $results | ignore
}
```

**Usage:**

```nu
nu tests/get.nu                     # full suite
nu tests/get.nu gpu-performance     # single script
nu tests/get.nu kbd-backlight       # single script
```

Output (on success):
```
── Waybar --get contracts ──
  ✓ volume
  ✓ mic
  ✓ brightness
  ✓ layout
  ✓ gpu-performance
  ✓ kbd-backlight
  6/6
```

Output (on failure):
```
── Waybar --get contracts ──
  ✓ volume
  ✗ gpu-performance
    stdout not valid JSON: read_socket;
  ...
```

---

## 12. Tests — `tests/set.nu` (rewritten)

Same structure as `get.nu`, but exercises action verbs. Verifies exit 0 and, where feasible, that state actually changed.

```nu
#!/usr/bin/env nu
# tests/set.nu — Exercise every action verb. Verifies exit 0 and (where possible)
# that observable state changed.
# Usage:
#   nu tests/set.nu              # all actions
#   nu tests/set.nu volume       # only volume actions
#
# WARNING: these are real state changes. Mic toggles, profile cycles, etc.
# Re-run the matching get.nu to confirm the bar reflects the new state.
use _lib.nu *

# Each case can optionally include `verify`: a closure called AFTER `run`
# that returns null on success, error string on failure. This lets us
# check "did state actually change?" not just "did exit code = 0?".
const CASES = [
    {
        name: "volume mute"
        run:  { ^volume --mute }
    }
    {
        name: "mic toggle"
        run:  { ^mic --toggle }
        verify: {|before|
            let after = ((^mic --get-status | from json).class)
            if $after != $before { null } else { $"class unchanged: ($before)" }
        }
        snapshot: { (^mic --get-status | from json).class }
    }
    {
        name: "brightness up"
        run:  { ^brightness --up }
    }
    {
        name: "brightness down"
        run:  { ^brightness --down }
    }
    {
        name: "layout change"
        run:  { ^layout --change }
        verify: {|before|
            let after = ((^layout --get | from json).class)
            if $after != $before { null } else { $"class unchanged: ($before)" }
        }
        snapshot: { (^layout --get | from json).class }
    }
    {
        name: "gpu cycle"
        run:  { ^gpu-performance --change }
        verify: {|before|
            let after = ((^gpu-performance --get | from json).class)
            if $after != $before { null } else { $"class unchanged: ($before)" }
        }
        snapshot: { (^gpu-performance --get | from json).class }
    }
    {
        name: "kbd up"
        run:  { ^kbd-backlight --up }
    }
    {
        name: "kbd down"
        run:  { ^kbd-backlight --down }
    }
]

def check_case [c: record]: nothing -> record {
    # Optional snapshot before
    let before = (
        if ($c | get -i snapshot) != null { do $c.snapshot } else { null }
    )

    let out = (do $c.run | complete)
    if $out.exit_code != 0 {
        return (fail $c.name $"exit ($out.exit_code): ($out.stderr | str trim | str substring 0..80)")
    }

    # Allow state to settle (waybar polls at 1Hz; daemon RPCs are fast but not instant)
    sleep 200ms

    # Optional verify closure compares before/after
    if ($c | get -i verify) != null {
        let issue = (do $c.verify $before)
        if $issue != null { return (fail $c.name $issue) }
    }

    pass $c.name
}

def main [filter?: string] {
    let cases = (
        if ($filter | is-empty) { $CASES }
        else { $CASES | where {|c| $c.name | str starts-with $filter} }
    )

    if ($cases | is-empty) {
        print $"(ansi red)No case matches '($filter)'(ansi reset)"
        print $"Available prefixes: ($CASES | get name | each {|n| $n | split row ' ' | get 0} | uniq | str join ', ')"
        return
    }

    print $"(ansi yellow_bold)⚠ Destructive — exercises real state changes(ansi reset)\n"
    let results = ($cases | each { check_case $in })
    report "Action verbs" $results | ignore
}
```

**Usage:**

```nu
nu tests/set.nu                 # all actions (full destructive sweep)
nu tests/set.nu volume          # only volume actions
nu tests/set.nu gpu             # only gpu cycle
nu tests/set.nu mic             # only mic toggle (with state-change verification)
```

The `verify` field is the key advanced pattern: it's a **deferred assertion** that runs AFTER the action with access to the pre-state via `before`. Mic toggle, layout change, and gpu cycle all use it to confirm the *observable state* changed, not just that the command exited cleanly.

---

## 13. Optional — `tests/run.nu` (umbrella)

If you want a single entry point that runs both suites and exits with a useful status:

```nu
#!/usr/bin/env nu
# tests/run.nu — Run both contract tests in sequence.
# Exits 0 if all pass, 1 otherwise.
use _lib.nu *

def main [
    --get-only   # skip action tests (non-destructive)
    --set-only   # skip contract tests
] {
    let get_pass = if $set_only { true } else { (do { nu tests/get.nu } | complete | get exit_code) == 0 }
    let set_pass = if $get_only { true } else { (do { nu tests/set.nu } | complete | get exit_code) == 0 }

    if $get_pass and $set_pass {
        print $"\n(ansi green_bold)All suites passed(ansi reset)"
        exit 0
    } else {
        print $"\n(ansi red_bold)One or more suites failed(ansi reset)"
        exit 1
    }
}
```

Wire it into your `justfile` if useful:

```just
test:
    nu tests/run.nu --get-only    # non-destructive CI sweep

test-all:
    nu tests/run.nu               # full sweep
```

---

## Apply order

1. **Drop in `_shared.nu`** — every script depends on `notify` and `capture` now. Without this first, nothing else compiles.
2. **Drop in the seven scripts** (`volume`, `mic`, `brightness`, `layout`, `powermenu`, `screenshot` in `desktop/scripts/`; `gpu-performance`, `kbd-backlight` in `host/g14/scripts/`).
3. **`just switch`** — no Nix-side changes needed; the script set hasn't changed, only the file contents.
4. **Restart waybar:** `pkill waybar; uwsm app -- waybar &`
5. **Drop in the test files** (`_lib.nu` patched with the two additions, `get.nu` replaced, `set.nu` replaced; optional `run.nu`).
6. **Run `nu tests/get.nu`** — should be 6/6 green.
7. **Run `nu tests/set.nu gpu`** — should cycle the profile and confirm state change.
8. **Run `nu tests/set.nu mic`** — should toggle mute and confirm state change. Re-run to restore.

---

## What you should see on the bar after this

```
[profile] [12:34] [workspaces]   ⌨ US   󰍬   󰕾 50%   󰃟 70%   󰌌    4%   wifi   on   91%   󱐌 Performance   [power]
```

- **Layout**: `⌨ US` (or `⌨ MX`). Full keymap name on hover.
- **Mic**: just the icon `󰍬`. Hover for state, click to toggle → single non-stacking notification.
- **Volume**: `󰕾 50%`. Hover says "scroll to adjust." Action goes through swayosd's OSD.
- **Brightness**: `󰃟 70%`. Same model.
- **Kbd backlight**: just the icon (changes with level). Hover for state. Cycle keys → single notification.
- **GPU profile**: `󱐌 Performance` (or whatever profile). Hover shows what the profile *does* ("Maximum — fans engaged, plugged in recommended").
- **Power**: opens walker picker.

No more redundant restatements, no more stacking notifications with `(3)` counters, no more `english (us, intl., with dead keys)` cluttering the bar.

---

## What's still on the floor

- **Clipboard pipeline** in `hyprland.conf:573` (`cliphist list | walker --dmenu | cliphist decode | wl-copy`). Same anti-pattern as the old powermenu — three-stage shell pipeline embedded in WM config. Easy `clipboard.nu` extraction following the v2 pattern, but not done here per scope.
- **`gpu-performance --change` keybind**. You have `bind = ,XF86Launch4, exec, gpu-performance --change` in `g14.nix`'s host-extras. If that key doesn't fire on your G14 (run `wev` to verify), pick a different physical key — possibly `$mainMod, F8` or one of the unbound M-row macros — and update host-extras.
- **Edge-case tests**. If asusd is down, what should gpu-performance return? Right now: `{text: "󰋖 Unknown", ...}`. That's defensible but untested. A future test pass could mock the daemon and verify graceful degradation.
