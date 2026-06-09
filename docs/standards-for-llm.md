# Nushell Standards & Gotchas (for LLM editors)

> Target Nushell **0.112.2**. Reader is a model editing `.nu` files in this repo. Optimize for
> not-breaking-the-config over prose. Every rule here came from a real failure or the official docs.

## Inspect the live config surface first

When unsure about a `$env.config` key, default, or available setting, run this (it prints the
version-correct, in-shell documentation for every setting):

```nu
config nu --doc | nu-highlight | bat        # or: config nu --doc | nu-highlight | less -R
```

Do not guess config keys from memory — Nushell renames/moves them between releases. Verify against
`config nu --doc` output for the running version.

---

## ☠️ CRITICAL — the failure modes that brick `config.nu`

A single parse error anywhere in `config.nu` aborts the **entire** file. Effect: zoxide (`z`), atuin
(`$ATUIN_SESSION`), `shellAliases`, and every custom command silently fail to load. External binaries
(`eza`, `yazi`, `nh`, `hx`) still work because they're on `PATH`, not defined in the config. So
"my aliases vanished but `eza` works" == config parse error, not a PATH problem.

### 1. `#` comments run to end-of-line — even mid-expression

`#` starts a comment that consumes the rest of the line, **including closing `)` and `}`**.

```nu
# ✗ BROKEN: the `)` and `}` are swallowed by the comment → unbalanced delimiters
1 => { hx ($matches | first # single hit) }

# ✓ FIX: comment goes AFTER everything closes, or on its own line
1 => { hx ($matches | first) } # single hit
```

Rule: **never place `#` before a `)` or `}` on the same line.** Put trailing comments after all
delimiters close, or on their own line.

### 2. Empty match arm = `null`, not `{}`

`{}` parses as an **empty record**, not an empty block. Use `null` for a no-op arm.

```nu
match $x {
    0 => null            # ✓ no-op
    1 => { do-thing }    # ✓ block runs
    _ => { other }
}
```

### 3. Editors double braces on paste

Helix/most editors with auto-pairs insert a phantom `}` when you paste text that already contains its
closing brace → "one too many braces". Two safe ways to write a `.nu` file:

```nu
# A) disable auto-pairs in helix before pasting
:set auto-pairs false

# B) write verbatim from the shell, bypassing the editor entirely (preferred for whole files)
r##'<file contents here>'## | save -f path/to/file.nu
```

### 4. Always parse-check before rebuilding

`nu` is a normal binary; validate a file in isolation without touching the real config:

```nu
nu -c "source path/to/file.nu"   # silent output == parses clean
```

Run this after **every** edit to a `.nu` file, before `just switch`.

---

## Raw strings (for writing files verbatim)

```nu
r#'literal, no $interpolation'#       # terminator: '#
r##'contains '# safely'##             # terminator: '##  (use when content has '#)
```

Pick enough `#` so the terminator sequence (`'#`, `'##`, …) does **not** appear inside the content.
Raw strings do no `$var`/`$"..."` interpolation — ideal for piping a whole script into `save -f`.

---

## Syntax cheat (verbatim forms)

| Need | Form |
|------|------|
| Typed custom command | `def name [arg: type]: input -> output { … }` |
| Library export | `export def name [...]: in -> out { … }` |
| CLI dispatch | `def main [--get --up --down --set: int] { if $up {…} else {…} }` |
| Run closure | `do $closure` |
| Capture external | `^cmd ...$args \| complete` → `{stdout, stderr, exit_code}` |
| Fire-and-forget | `do { cmd } \| complete \| ignore` |
| Spread list as args | `cmd ...$list` |
| External explicitly | `^cmd` or `run-external cmd ...$args` |
| Null-safe field | `$rec \| get -o key`  /  `$rec.key?`  /  `$list \| get 0?` |
| Regex parse | `parse -r '(?P<name>\d+)'`  /  template: `parse "{k}={v}"` |
| Hash → int | `$s \| hash sha256 \| str substring 0..6 \| into int --radix 16` |
| Closure captures scope | `let a = …; run_silent { cmd ...$a }`  (✓ `$a` visible inside) |

### Daemonizing externals — do NOT use `complete`

Commands that fork a background process holding inherited fds (`hyprshot`, `wl-copy`) will make
`complete` wait forever for the pipe to drain. Redirect stdio instead and call bare:

```nu
hyprshot -m region -o $dir out> /dev/null err> /dev/null
$chosen | cliphist decode | wl-copy out> /dev/null err> /dev/null
```

`run_silent`/`complete` are only for commands that actually exit (e.g. `swayosd-client`, `asusctl --set`).

---

## Environment & config

- **PATH is a list** in Nushell (auto-converted from the inherited string). Extend it with the stdlib helper:
  ```nu
  use std/util "path add"
  path add ($env.HOME | path join ".local/bin")   # prepends (higher precedence) by default
  ```
  Manual form (no stdlib dep) is also fine: `$env.PATH = ($env.PATH | split row (char esep) | prepend $p | uniq)`.
- **Home-Manager gotcha:** Nushell does **not** source HM's POSIX `hm-session-vars.sh`, so
  `home.sessionPath` / `home.sessionVariables` do **not** automatically reach `nu`. A manual `$env.PATH`
  line in `programs.nushell.extraEnv` is doing real work — don't delete it thinking sessionPath covers it.
- **Set config keys individually**, never wholesale: assigning `$env.config = { … }` drops every key not
  in the new record (Nushell then re-merges internal defaults). Prefer:
  ```nu
  $env.config.show_banner = false       # ✓ field assignment
  ```
- `show_banner` accepts `true | "full" | "short" | false | "none"` on 0.112.
- stdlib is split into submodules (`std/util`, `std/config`, …) and has had occasional bugs; prefer plain
  builtins when a one-liner does the job.

---

## Repo code standards (enforce on every change)

| Rule | Concretely |
|------|------------|
| Type signatures on every function | `def name []: input -> output` — for small fns the signature *is* the doc |
| Functional > imperative | comprehensions/`each`/`reduce`/pipelines; **no** `mut x = [] ; $x = ($x \| append …)` loops |
| Small composable helpers | split a fn before it needs an internal section comment |
| Records over positional tuples | `{icon, desc, class}` not `[$icon $desc $class]` (beyond pairs) |
| Comments explain *why*, never *what* | delete any comment that restates the code |
| Library helpers are `export def` | live in `_shared.nu` (runtime) or `_lib.nu` (tests); consumers `use … *` |
| CLI mains dispatch by flag | `def main [--get --change] { … }`; status/read flag is **`--get`** everywhere |
| Closures as data | `run_silent { side-effect }`, `do $block` |
| No dead code | flag pre-existing dead code in a file you touch; don't delete unrelated dead code unprompted |
| Naming | `SCREAMING_CASE` consts, `snake_case` fns/vars, `kebab-case-flags` |

### Waybar status-script shape (canonical)

```nu
#!/usr/bin/env nu
use _shared.nu *
def state []: nothing -> record { … }                 # read raw state
def meta [s]: nothing -> record { {icon:…, desc:…} }   # state -> presentation (icon, desc, class)
def main [--get --up --down] {
    if $up   { run_silent { … }; osd $"…" $icon }      # mutate + OSD
    else if $down { … }
    else { status $text $tooltip $class }              # else: emit waybar JSON
}
```

`_shared.nu` primitives to reuse (don't reinvent): `as_json`, `notify`, `capture` (stdout, stderr discarded),
`run_silent`, plus the planned `level3`, `status`, `osd`.

### Test shape (canonical)

Each test returns `{name, passed, skipped, detail}`. Build results with `_lib.nu`: `pass/fail/skip/check`,
guard existence with `run_or_skip`/`check_exec`/`check_grep`, render with `report`/`audit`/`orchestrate`,
print section headers with `section`. Discover hardware with `first-nvme` (in `_lib.nu`).

---

## Pre-edit checklist (run mentally before saving any `.nu`)

1. No `#` before a `)` or `}` on the same line.
2. Match no-ops are `null`, not `{}`.
3. Wrote the file via raw-string `save` **or** with editor auto-pairs off.
4. `nu -c "source <file>"` parses clean.
5. Type signature present on every `def`.
6. No `mut … append` loop where a pipeline works.
7. After all edits: `just switch`, then re-run `nu <consumer> --get` / the test suites to confirm parity.
