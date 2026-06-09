# Nushell Scripts — Boilerplate Reduction Plan

> Goal: push the recurring patterns in the `.nu` scripts down into the two existing
> libraries (`_shared.nu` for waybar/runtime scripts, `_lib.nu` for tests), without
> inventing abstractions for one-off code.

## Locked decisions

- **(1A)** Phase-1 helpers only for waybar (`level3`, `status`, `osd`). Do **not** abstract the
  "mutate → re-read → meta → osd" ritual — the commands/messages differ per script.
- **(2A)** `class` stays an **explicit argument** to `status`. Do not try to derive it inside the helper;
  the three derivations (`meta.class`, `$code | str downcase`, `$LEVELS | get $lvl`) are genuinely different.
- **(3)** Standardize the *status/read* flag to `--get` everywhere. Only `mic.nu` deviates
  (`--get-status`). Rename it and sync callers. Action flags (`--up/--down/--change/--toggle/--mute/...`)
  stay script-specific.
- **Out of scope:** `fn.nu` (interactive shell helpers) beyond adding the missing type signatures.

## Where things live

- `src/home/desktop/scripts/_shared.nu` — waybar/runtime lib. `export def` only. Consumed by every
  desktop **and** g14 script (g14's `_shared.nu` is a symlink; both install into `~/.local/bin/`).
- `tests/_lib.nu` — test framework lib. Already factored (`pass/fail/skip/check/report/audit/orchestrate`).

New exports are auto-available to any script that already does `use _shared.nu *` / `use _lib.nu *`.

---

## Phase 1 — `_shared.nu` (waybar)

- [ ] **Add `level3`** — collapse the duplicated 66/33 threshold ladder.
  ```nu
  # pct + three icons -> {icon, class}. Buckets: >66 high, >33 medium, else low.
  export def level3 [pct: int, high: string, med: string, low: string]: nothing -> record {
      if $pct > 66 { {icon: $high, class: "high"} }
      else if $pct > 33 { {icon: $med, class: "medium"} }
      else { {icon: $low, class: "low"} }
  }
  ```
  - `brightness.nu` `meta` → `(level3 $pct "󰃠" "󰃟" "󰃞") | merge {desc: "Scroll to adjust"}`
  - `volume.nu` `meta` (non-muted branch) → `(level3 $pct "󰕾" "󰖀" "󰕿") | merge {desc: "Scroll to adjust, click to mute"}`
    (the muted branch stays as-is)

- [ ] **Add `status`** — one waybar-JSON emitter; replaces six hand-written `as_json {…}` blocks.
  ```nu
  export def status [text: string, tooltip: string, class: string]: nothing -> string {
      as_json { text: $text, tooltip: $tooltip, class: $class }
  }
  ```
  Call sites to convert:
  - `brightness.nu get_waybar` → `status $"($m.icon) ($p)%" $m.desc $m.class`
  - `volume.nu get_waybar` → `status $"($m.icon) ($s.pct)%" $m.desc $m.class`
  - `mic.nu` else → `status $m.icon $m.desc $m.class`
  - `layout.nu` else → `status $"⌨ ($code)" $now ($code | str downcase)`
  - `gpu-mode.nu` else → `status $"($m.icon) ($now)" $m.desc ($now | str downcase)`
  - `kbd-backlight.nu` else → `status $m.icon $m.desc ($LEVELS | get $lvl)`

- [ ] **Add `osd`** — wraps the swayosd-client *custom-message* form (3 sites).
  ```nu
  # Custom OSD message + icon, optional progress bar (0.0..1.0). Fire-and-forget.
  export def osd [message: string, icon: string, --progress: float] {
      let args = ([--custom-message $message --custom-icon $icon]
          | append (if $progress != null { [--custom-progress $progress] } else { [] }))
      run_silent { swayosd-client ...$args }
  }
  ```
  - `layout.nu` → `osd $"Kbd set: ($code)" "input-keyboard"`
  - `gpu-mode.nu` → `osd $"GPU Mode: ($m.icon)" $m.icon`
  - `kbd-backlight.nu` → `osd $"($m.icon) Keyboard: ($LEVELS | get $now | str capitalize)" $m.icon --progress $pct`
  - Leave `brightness.nu`/`volume.nu` swayosd calls alone — they use `--brightness`/`--output-volume`,
    not the custom-message form (single calls, no duplication worth wrapping).

**Verify Phase 1:** `nu -c "source src/home/desktop/scripts/_shared.nu"` parses clean, then from the
scripts dir confirm byte-identical output before/after for each: `nu brightness.nu --get`, `nu volume.nu --get`,
`nu mic.nu --get`, `nu layout.nu --get`, `nu gpu-mode.nu --get`, `nu kbd-backlight.nu --get`.

---

## Phase 2 — `tests/_lib.nu`

- [ ] **Move `first-nvme` into `_lib.nu`** (single canonical regex), delete the two local copies.
  ```nu
  export def first-nvme []: nothing -> string {
      ls /dev | get name | where ($it =~ 'nvme\dn\d$') | first
  }
  ```
  - `health-disk.nu` already does `use _lib.nu *` → just delete its local def.
  - `bench-disk.nu`'s copy is **pre-existing dead code** (defined, never called in `main`). Remove it as
    part of the dedup. (Flagging per the repo rule — veto if you'd rather keep it.) `bench-disk.nu` does not
    otherwise import `_lib.nu`; only add `use _lib.nu *` if it ends up needing `section` (below).

- [ ] **Add `section`** — kills the inline `━━ … ━━` header repeated ~7×.
  ```nu
  export def section [title: string, --color: string = "cyan_bold"] {
      print $"(ansi ($color))━━ ($title) ━━(ansi reset)"
  }
  ```
  - Emits the header line only; callers keep their own blank-line spacing (`print ""` where they had `\n`).
  - Convert sites in `bench-disk.nu` (3), `bench-net.nu` (2), `bench-ram.nu` (1), `health-disk.nu` (2).
  - `bench-disk.nu` needs `use _lib.nu *` added once for this.

- [ ] **Add `run_or_skip`** — DRY the `which … | is-empty → skip` guard (3 sites in `health-gpu.nu`).
  ```nu
  export def run_or_skip [name: string, cmd: string, body: closure]: nothing -> any {
      if (which $cmd | is-empty) { return (skip $name $"($cmd) not found") }
      do $body
  }
  ```
  - `health-gpu.nu` `test-nvidia-smi` / `test-power` / `test-offload` → wrap the guarded body.
  - Scope note: this only abstracts the existence guard. The `| complete` + exit-code branch stays in each
    body (the post-parse logic genuinely differs). Don't push further.

**Verify Phase 2:** `nu -c "source tests/_lib.nu"` parses clean, then run the affected suites
(`tests.just` recipes / `nu tests/health-disk.nu`, `nu tests/health-gpu.nu`, `nu tests/bench-*.nu`)
and confirm pass/skip counts are unchanged.

---

## Phase 3 — local cleanups (no new lib surface)

- [ ] **`health-gpu.nu` `test-offload`**: replace `mut results = [] ; append …` with a pipeline-built list
  (matches the repo's "iterators over imperative loops" rule), and factor the duplicated glxinfo
  renderer-parse into one local helper:
  ```nu
  def renderer [out: record]: nothing -> string {
      $out.stdout | lines | find "OpenGL renderer string" | first
          | str replace "OpenGL renderer string: " "" | str trim
  }
  ```

- [ ] **`fn.nu` signatures** (only `fn.nu` touch in scope): add `: nothing -> nothing` to `to-txt` and `dotenv`
  to match `fhx` and the repo convention. No logic change.

---

## Phase 4 — flag standardization (decision 3)

- [ ] `rg -n 'get-status' src tests` to find callers first (likely none in `waybar.jsonc`/`hyprland.lua`;
  mic status isn't a bar module — `mic` is only bound to `--toggle`).
- [ ] `mic.nu`: rename `--get-status` → `--get`.
- [ ] Update any caller the grep found.
- [ ] Confirm the status flag is now `--get` across all six status scripts.
  (Optional, not now: `mic --toggle` vs `volume --mute` still diverge — leave it; action flags are allowed
  to be script-specific.)

---

## Definition of done

- All six status scripts emit byte-identical `--get` JSON vs. the pre-refactor output.
- OSD still fires on `--up/--down/--change` for brightness, volume, layout, gpu-mode, kbd-backlight.
- `just switch` builds clean; waybar renders unchanged after reload.
- Test suites report the same pass/skip/fail counts.
- `rg 'get-status'` returns nothing.
- No `mut`/manual-append loops remain in `test-offload`; no duplicated `first-nvme`; no inline `━━` headers.

## Execution order

Phase 1 → verify → Phase 2 → verify → Phase 3 → Phase 4 → `just switch` → run suites.
Each phase is independently shippable; parse-check the touched lib before every rebuild.
