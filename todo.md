# NixOS Desktop Module — Architectural Spec

> **Status:** Pre-implementation alignment.
> **Author role:** Principal Architect.
> **Scope:** `src/home/desktop/` overhaul, theme unification, package relocation, nu script verification.

---

## 0. Executive Summary

This spec finalizes the migration of the `desktop` Home Manager module from a fragmented mix of inline Nix attribute sets, sh scripts, and partial Stylix wiring into a coherent, single-purpose module organized around three principles: **native config files own their format**, **Nix owns composition and theme injection**, and **one file per concern with no redundant indirection**. The architecture eliminates the parallel `packages/desktop.nix` consumer-less file, centralizes all theming in a single `stylix.nix` module, and resolves the Home Manager-vs-manual-config conflicts that are currently producing build errors and broken keybinds. The long-term bet is that native configs (`.conf`, `.css`, `.lua`, `.rasi`, `.jsonc`) remain stable across upstream Hyprland/Waybar/Rofi versions while the Nix layer absorbs only what reproducibility requires — color injection and file placement — keeping the system upgradable when Stylix, Hyprland, or Home Manager APIs evolve.

---

## 1. Context & Constraints

**Project:** Dendritic NixOS configuration for ASUS Zephyrus G14, generation 204, currently mid-refactor.

**Goal:** A reproducible, modular Hyprland-centric desktop where every config file is in its native format, theming is unified through Stylix + a single placeholder injection pass, and all imperative glue is nu-script-based.

**Architectural rules (carried from established repo conventions):**
- Dendritic pattern — every file is a self-contained `flake-parts` module under `inputs.self.homeModules.*` or `inputs.self.lib.*`.
- No `imports = [ ... ]` chains at composition points beyond `common.nix` and `profiles/*`.
- Native formats win over Nix attrs when both are viable (`.conf`/`.css`/`.lua`/`.rasi` preferred over `services.X.settings = {...}`).
- Modern Rust tooling preferred (`ripgrep`, `fd`, `bat`, `eza`); shell logic written in nu, not bash.
- One concern per file — composition happens via the dendritic registry, not by stuffing files.

**Out of scope for this spec:**
- Replacing or extending the Hyprland keybind set.
- Reworking `host/g14/`, `system/`, or `users/` modules.
- The `wallpaper.png` asset itself (user will provide).
- `disko` adoption (flagged as future work).

**Assumptions made (flagged):**
- [ASSUMPTION] The user wants HM-managed services dropped where they conflict with manual native files — i.e., the native file is the source of truth, not the Nix attribute set.
- [ASSUMPTION] Stylix targeting `wezterm` is to be disabled because the manual `.wezterm.lua` already overrides it; the user's "unified theme works for helix + wezterm + yazi" claim is partly Stylix and partly coincidence of using JetBrainsMono + transparent background. The wezterm portion is fragile and should be made explicit.
- [ASSUMPTION] `volume.nu` is dead code (Hyprland binds use `wpctl` directly) and will be removed.
- [ASSUMPTION] Rofi is to be added to packages; the user has not signaled interest in switching to fuzzel/wofi.

---

## 2. Architecture Overview

The desktop module sits at the leaf of the dendritic tree under `inputs.self.homeModules.desktop`. It composes one or more sub-modules and reads native files at evaluation time, injecting theme tokens through a pure-Nix substitution function before writing them into the user's `~/.config` tree.

```
┌─────────────────────────────────────────────────────────────────┐
│  profiles/common.nix                                            │
│    imports → homeModules.desktop, homeModules.shell             │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  src/home/desktop/desktop.nix     (composition root)            │
│    imports →                                                    │
│      • homeModules.stylix         (theme palette + Stylix cfg)  │
│    consumes →                                                   │
│      • theme arg (via _module.args)                             │
│      • applyTheme function (defined locally)                    │
│    declares →                                                   │
│      • HM program/service enables (only where they don't       │
│        collide with manual files)                              │
│      • home.file writes (native configs + scripts)             │
│      • home.packages (Hyprland-adjacent desktop tools)         │
└──────────────────────┬──────────────────────────────────────────┘
                       │ readFile + applyTheme
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│  Native config layer (edited as plain text, LSP-friendly)       │
│    hyprland.conf, hyprlock.conf, hypridle.conf,                 │
│    waybar.jsonc, waybar-style.css,                              │
│    rofi.rasi, dunst.conf,                                       │
│    swayosd-style.css, wezterm.lua                               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Script layer  src/home/desktop/scripts/*.nu                    │
│    kbd-{backlight,layout,mic,performance}.nu                    │
│    screenshot.nu, powermenu.nu                                  │
│    (symlinked → ~/.local/bin via home.file)                     │
└─────────────────────────────────────────────────────────────────┘
```

**Core domain:** desktop composition (file placement + theme injection).
**Supporting domain:** package selection (delegated to `home.packages` inline), nu script execution surface (autonomous, only depends on shell PATH).

---

## 3. Design Patterns & Code Standards

### 3.1 Composition Root pattern (`desktop.nix`)

- **What:** A single Home Manager module that owns all wiring for the graphical session.
- **Why:** Eliminates the prior fan-out across `dunst.nix`, `hypridle.nix`, `hyprland.nix`, `hyprlock.nix`, `rofi.nix`, `waybar.nix`, `wezterm.nix`, `swayosd.nix`. Each of those modules had ~10 lines of real logic; the indirection cost (one file per ~10 lines, multiple registry entries) outweighed the modularity benefit because nothing else in the system consumed them individually. Consolidation reduces eight registry lookups to one.
- **How:** `desktop.nix` imports only `stylix.nix`, receives `theme` via `_module.args`, and emits all `programs.*`, `services.*`, `home.file.*`, and `home.packages` declarations directly.
- **Year-3 protection:** New desktop components (e.g., adding waybar plugins, switching from rofi to wofi) become single-file edits, not module-graph surgery.
- **Year-10 protection:** When Stylix or HM modules deprecate options, only one file needs updating.

### 3.2 Native Config + Placeholder Injection pattern

- **What:** Each upstream tool's config is stored in its native file format. The file contains `@token@` placeholders for any value that must be derived from the central theme. A Nix-side `applyTheme` function performs `builtins.replaceStrings` at evaluation time before writing the file to `home.file`.
- **Why:** Native formats are upstream-stable, LSP-supported (e.g., hyprls for `.conf`), and copy-pasteable from community examples. Pure-Nix attribute sets for these tools (e.g., `services.dunst.settings`) lock you into HM's schema, which drifts.
- **How:**
  - Native file declares `@tokenName@` everywhere a theme value appears.
  - `desktop.nix` defines `placeholders` attrset mapping `@tokenName@` → resolved value (color, integer, path).
  - `applyTheme = text: builtins.replaceStrings (attrNames p) (attrValues p) text` is applied to every `readFile` invocation that needs theming.
  - Files that need no theming (`hypridle.conf`, `waybar.jsonc`, `wezterm.lua`) are written via raw `readFile` without `applyTheme`.
- **Standards:**
  - Token convention: `@semantic_name@` (e.g., `@base@`, `@mauve@`). For raw hex (Hyprland's `rgb(abcdef)` syntax), suffix with `_raw` (e.g., `@mauve_raw@`).
  - Numeric tokens use `toString` and are referenced without quotes in native files.
  - Every placeholder used in a native file MUST be declared in `placeholders` — unresolved tokens reach the runtime config and break the program silently. A fitness function (see §8) enforces this.
- **Year-3 protection:** Switching color schemes is a one-line edit in `stylix.nix`.
- **Year-10 protection:** If Stylix dies or the user migrates off it, only the theme palette source needs swapping; the placeholder injection layer survives.

### 3.3 Stylix as the Theme Authority + Manual Escape Hatches

- **What:** Stylix owns the base16 palette generation, font configuration, cursor, and *only the targets it can satisfy without conflict*. Manual files own everything else.
- **Why:** Stylix's "auto-enable everything" mode collides with custom configs. The current setup half-trusts Stylix (it's enabled for wezterm, gtk, qt) and half-doesn't (waybar, hyprland, rofi, dunst, hyprlock are explicitly disabled). This is the right shape but is misconfigured.
- **How:**
  - `stylix.autoEnable = false` — no implicit targets.
  - Explicit allow-list of Stylix targets: `gtk`, `qt`, `bat`, `btop`, `fish` (terminal palette propagation only where the manual config doesn't override).
  - `wezterm` target: DISABLED. The manual `.wezterm.lua` is the source of truth; Stylix would write a competing config that wezterm ignores in favor of `~/.wezterm.lua`. Pretending otherwise is fragile.
  - `helix`: enabled IFF `programs.helix.enable = true` and there is no manual `xdg.configFile."helix/config.toml".source`. Currently shell.nix sources a manual file — this is a conflict that must be resolved (see §5 DECISION 4).
- **Standards:** Every Stylix target is explicitly listed (allow-list, not deny-list). Adding a new themed program is a deliberate decision, not an opt-out.

### 3.4 Script Surface pattern (nu scripts)

- **What:** Imperative logic lives in standalone nu scripts under `desktop/scripts/`, symlinked to `~/.local/bin` via `home.file`. They expose a `--get` mode (returns JSON for Waybar) and a `--change`/`--toggle`/etc. mode (side-effect, optional notification).
- **Why:** Nu's structured data model makes JSON emission trivial and parsing of `hyprctl`/`asusctl`/`wpctl` output declarative. Sh scripts for this glue were brittle (string parsing of command output) and not type-safe.
- **How:**
  - Every script declares its CLI surface with `def main [--flag1, --flag2]`.
  - `--get` modes emit a single JSON record to stdout with no stderr noise.
  - State-changing modes use `notify-send` with `string:x-dunst-stack-tag:<unique>` to prevent notification spam.
  - All scripts have `#!/usr/bin/env nu` and are marked `executable = true` in `home.file`.
- **Standards:**
  - No script may assume PATH beyond `/run/current-system/sw/bin` + `~/.local/bin`. Cross-script invocations use absolute paths or unprefixed names that resolve via session PATH.
  - Error paths exit non-zero with stderr messages (caught by Waybar to surface "—" in the bar).
  - Hardcoded device names (`asus-keyboard`) are flagged as fragile and tracked for parameterization.

### 3.5 Logging / Observability

- **What:** Hyprland writes to `~/.local/share/hyprland/hyprland.log`. Waybar logs to its journal. Nu scripts log to stderr when invoked manually; their stdout is consumed by Waybar.
- **Standard:** When a script's `--get` mode returns a malformed JSON, Waybar shows blank. To debug, the user runs the script directly in a terminal — scripts must therefore be safe to invoke standalone with no Hyprland/Waybar context.

---

## 4. Component Map & Directory Structure

### Proposed tree (post-refactor)

```
src/home/desktop/
├── desktop.nix              # composition root
├── stylix.nix               # theme palette + Stylix config (renamed from theme.nix)
├── wallpaper.png            # asset (user-provided, placeholder until then)
├── hyprland.conf            # native, @placeholders@
├── hyprlock.conf            # native, @placeholders@
├── hypridle.conf            # native, no placeholders
├── waybar.jsonc             # native, no placeholders (colors live in CSS)
├── waybar-style.css         # native, @placeholders@
├── rofi.rasi                # native, @placeholders@
├── dunst.conf               # native, @placeholders@
├── swayosd-style.css        # native, @placeholders@ (NEW — extracted from desktop.nix)
├── wezterm.lua              # native, no placeholders (manual control)
└── scripts/
    ├── kbd-backlight.nu
    ├── kbd-layout.nu
    ├── kbd-mic.nu
    ├── kbd-performance.nu
    ├── screenshot.nu
    └── powermenu.nu         # NEW — replaces inline bash in desktop.nix
                             # NOTE: volume.nu deleted (unused)
```

### Deletions

- `src/home/packages/desktop.nix` — its `tools` list moves inline into `desktop.nix`; `apps`/`creative`/`office` lists remain consumed by `profiles/dev.nix`. The file is split, not fully deleted: `tools` migrates out, the rest stays under a slimmer attribute name (see Component breakdown below).

### Component breakdown

| Component | Location | Responsibility | Interfaces | Must NOT |
|---|---|---|---|---|
| `desktop` composition root | `desktop.nix` | Wire HM programs, write native configs with theme injection, declare desktop package set | Exposes `homeModules.desktop` | Contain inline CSS/conf/lua bodies (extract to files) |
| `stylix` theme module | `stylix.nix` | Define color palette, style tokens (radii, widths), Stylix base16Scheme + fonts + cursor | Exposes `homeModules.stylix`, provides `_module.args.theme` | Contain placeholder logic (that belongs to `desktop.nix`) |
| Native config files | `*.conf`, `*.css`, `*.rasi`, `*.lua`, `*.jsonc` | Hold upstream-format config with `@token@` placeholders | Consumed by `readFile + applyTheme` | Reference values not declared in `placeholders` |
| Script surface | `scripts/*.nu` | Glue logic (waybar JSON producers, keybind action handlers) | CLI flags (`--get`, `--change`, etc.); JSON on stdout | Hardcode user paths; depend on env vars beyond `$HOME` and PATH |
| `cli.media` package group (NEW) | `packages/cli.nix` | Media CLI tools (`yt-dlp`, future additions) | Exposes `lib.pkgsets.cli.media` | Contain GUI applications |
| `desktop.apps` package group | `packages/desktop.nix` | Desktop applications (`spotify`, `brave`, `cheese`, etc.) | Exposes `lib.pkgsets.desktop.apps` | Contain CLI-only tools |
| `desktop.creative`/`office` | `packages/desktop.nix` | Specialized application groups | As before | — |

---

## 5. Trade-off Analysis

```
DECISION 1: HM module vs manual native file for Waybar/Wezterm/Hypridle
OPTIONS CONSIDERED:
  A. Enable programs.X.enable AND write home.file."config/X/..." → current state
     pros: get HM's package management, systemd service supervision
     cons: HM module writes to the same path → conflict (build error or
           silent overwrite); inconsistent ownership
  B. Drop programs.X.enable; write home.file only; add package to home.packages
     pros: single source of truth (the native file); no conflicts
     cons: lose HM systemd unit auto-generation; must manage service via hyprland.conf
           exec-once or manual systemd.user.services
  C. Drop home.file; use programs.X.settings with parsed JSON/TOML
     pros: full HM integration; type checking
     cons: lose native file format; lose LSP; gain Nix attribute syntax noise
CHOSEN: B for waybar/wezterm/hypridle; B is the only option consistent with
        "native files own their format" principle from §3.2.
REASON: The whole point of the migration is that native files are the source
        of truth. Option A is the current broken state. Option C undoes the
        native-file work just completed.
REVISIT IF: HM's module ecosystem gains zero-conflict layering (e.g., a
        `programs.waybar.useNativeConfig = true` option). Not on horizon.
```

```
DECISION 2: swayosd service management
OPTIONS CONSIDERED:
  A. services.swayosd.enable = true (HM option)
  B. Manual systemd.user.services.swayosd-server unit
  C. Both (current state)
CHOSEN: A
REASON: If the HM option exists, it's strictly better — HM handles dependency
        ordering with graphical-session.target, restart policy, and package
        wiring in one line. Manual unit is duplication. If the HM option does
        NOT exist (must verify), fall back to B and remove the duplicate.
REVISIT IF: HM swayosd module is found to be missing or buggy.
```

```
DECISION 3: Wallpaper handling while asset is missing
OPTIONS CONSIDERED:
  A. Commit a 1x1 black PNG as a placeholder until the real asset is added
  B. Conditional wallpaper: omit stylix.image and the swww exec-once if file
     absent
  C. Use a NUR/nixpkgs wallpaper as a temporary default
CHOSEN: A
REASON: Simplest. A 1-byte commit makes the build succeed; swapping the asset
        later requires no code change. Option B introduces conditional Nix
        logic for a temporary state. Option C creates an upstream dependency
        for a stopgap.
REVISIT IF: User wants procedurally-generated wallpapers or per-profile
        wallpaper switching.
```

```
DECISION 4: Stylix vs manual file for Helix
OPTIONS CONSIDERED:
  A. Stylix-themed: drop manual helix.toml, set programs.helix.enable + Stylix
     target enabled. Helix theme is generated from base16.
  B. Manual: keep helix.toml as source, set targets.helix.enable = false.
  C. Hybrid: programs.helix.settings = { theme = "catppuccin_mocha"; ... }
     in Nix; Stylix disabled for helix specifically.
CHOSEN: B [HIGH RISK — user said "unified theme works" so changing this may
        regress what currently works]
REASON: The user's prior statement that helix+wezterm+yazi share a unified
        theme is currently produced by helix's own catppuccin_mocha theme
        (declared in helix.toml line 1), wezterm's transparent background +
        font choice, and yazi's default theme — NOT by Stylix. Disabling
        Stylix's helix target makes this explicit and stops Stylix from
        someday breaking the manual config.
REVISIT IF: User wants a single color authority (would require Option C).
```

```
DECISION 5: Package list ownership (desktop.tools)
OPTIONS CONSIDERED:
  A. Keep packages/desktop.nix exposing tools/apps/creative/office groups
  B. Inline tools into desktop.nix; keep apps/creative/office in packages/
  C. Inline everything into desktop.nix
CHOSEN: B
REASON: `tools` is consumed ONLY by `desktop.nix` (1 consumer). Indirection
        through `lib.pkgsets.desktop.tools` adds a lookup step without
        decoupling. `apps`/`creative`/`office` are consumed by profiles/dev.nix
        and might be consumed by future profiles — they retain their abstraction.
        yt-dlp moves to a new cli.media group (it's a CLI, not desktop).
        cheese moves to desktop.apps (it's a webcam GUI).
REVISIT IF: A second consumer of `tools` appears (e.g., a `minimal-desktop`
        profile).
```

```
DECISION 6: Powermenu implementation
OPTIONS CONSIDERED:
  A. Inline bash in desktop.nix (current state)
  B. Standalone nu script in scripts/powermenu.nu
  C. Direct rofi exec with inline command in waybar.jsonc
CHOSEN: B
REASON: Consistency — every other glue script is .nu under scripts/. Inline
        bash in desktop.nix is the only sh holdout in the desktop module.
        Removing it completes the sh→nu migration objective.
REVISIT IF: User decides to drop nu shell entirely (would require ALL scripts
        to migrate together).
```

```
DECISION 7: Adopt disko now or defer
OPTIONS CONSIDERED:
  A. Adopt disko in a separate phase after desktop work stabilizes
  B. Adopt disko in parallel with desktop work
  C. Defer indefinitely
CHOSEN: A
REASON: Disko replaces hardware-configuration.nix — the last
        non-reproducible part of the config. High value, but orthogonal to
        the desktop refactor. Bundling them risks scope creep on a refactor
        that's already mid-flight.
REVISIT IF: Hardware changes force re-running nixos-generate-config anyway.
```

---

## 6. Phased Implementation Plan

### Phase 1 — Foundation: Build-Blocking Fixes
**Goal:** System rebuilds successfully and all keybinds dispatch (even if some scripts misbehave).

Components to build:
- Wallpaper placeholder PNG committed.
- Rofi added to the desktop package list (inline in `desktop.nix`).
- HM module conflicts resolved (drop `programs.waybar.enable`, `programs.wezterm.enable`, `services.hypridle.enable` where they conflict with `home.file`; keep packages in `home.packages`).
- swayosd: keep HM service OR manual unit (whichever proves to be the working one) — remove the other.
- Verify rendered hyprland.conf has zero `@...@` placeholders left after substitution (visual grep or fitness function).

Dependencies: none.

Exit criteria:
- `nixos-rebuild switch` completes without errors.
- Hyprland starts; SUPER+space opens rofi; SUPER+W kills active window; SUPER+ALT+S triggers screenshot.
- Waybar renders without "module failed" entries.

Risk flags:
- [HIGH RISK] swayosd HM option may not exist; fallback to manual unit must be tested.
- [REVISIT] PATH inheritance to Hyprland exec context — if SUPER commands launch but scripts fail, `home.sessionPath` propagation is the culprit.

---

### Phase 2 — Structural Cleanup: Restructure & Extract
**Goal:** File layout matches §4. No behavioral changes.

Components to build:
- Rename `theme.nix` → `stylix.nix`; merge Stylix configuration block from `desktop.nix` into it. `_module.args.theme` continues to be exposed.
- Extract inline swayosd CSS from `desktop.nix` → `swayosd-style.css` (with `@placeholders@`).
- Extract inline bash powermenu from `desktop.nix` → `scripts/powermenu.nu`. Convert case statement to nu match.
- Delete `volume.nu` (unused).
- Migrate `desktop.tools` package list inline into `desktop.nix`; remove `tools` from `packages/desktop.nix`.
- Move `yt-dlp` → new `cli.media` group in `packages/cli.nix`.
- Move `cheese` → `desktop.apps` in `packages/desktop.nix`.
- Update `profiles/dev.nix` `home.packages` composition to drop `desktop.tools` reference (now provided directly by `desktop` module's own `home.packages`).
- Verify the dendritic registry no longer exposes deleted modules (`homeModules.theme` if renamed, etc. — update consumers).

Dependencies: Phase 1 complete.

Exit criteria:
- File tree matches §4 exactly.
- `nixos-rebuild switch` succeeds with no behavioral regressions.
- `just check` (alejandra + nix flake check) passes.

Risk flags:
- Renaming `homeModules.theme` → `homeModules.stylix` breaks any consumer that imported the old name. Search must be exhaustive.

---

### Phase 3 — Script Verification & Hardening
**Goal:** Every nu script is verified to produce correct output against the live system. Hardcoded fragilities are addressed.

Components to build:
- Run each script's `--get` mode in a terminal; verify JSON output against the schema documented in §8.
- Verify keyboard device name (`asus-keyboard`) by running `hyprctl devices -j | from json | get keyboards | get name`. If it doesn't match, update `kbd-layout.nu`.
- Verify `wpctl get-volume @DEFAULT_AUDIO_SOURCE@` output format matches `kbd-mic.nu` parsing; if positional `get 2?` is fragile, switch to regex-based extraction.
- Test SwayOSD invocation paths (`kbd-mic --toggle`, `volume --up`/etc. if reintroduced).
- Confirm `screenshot --region` / `--screen` writes to `~/Pictures/Screenshots/` and that hyprshot is on PATH at Hyprland exec context.

Dependencies: Phase 2 complete.

Exit criteria:
- All Waybar custom modules display non-empty text.
- All Hyprland binds that invoke scripts produce expected side effects + notifications.
- Output of `kbd-performance --get` matches the reference produced earlier: `{"text":"󰓅","tooltip":"Profile: Performance" }`.

Risk flags:
- [REVISIT] Hardcoded `asus-keyboard` name will break on hardware refresh.

---

### Phase 4 — Theme Coherence Pass
**Goal:** Stylix and manual themes agree across all programs.

Components to build:
- Audit which programs are *actually* themed by Stylix (run `helix --tutor`, open `wezterm`, run `btop`, open a GTK app, open a Qt app — visually confirm Catppuccin Mocha).
- Verify the manual `.wezterm.lua` is not blocked by Stylix-generated wezterm config (check if `~/.config/wezterm/wezterm.lua` exists and shadows `~/.wezterm.lua`).
- Decide DECISION 4 outcome based on observation: if helix theming via Stylix works and the manual `helix.toml` isn't overriding it, keep manual. Otherwise reconcile.

Dependencies: Phase 3 complete.

Exit criteria:
- Visual consistency check: opening any themed program shows Catppuccin Mocha colors matching `stylix.nix` palette.
- No "two themes fighting" symptoms (e.g., title bar wrong color, terminal background different from window border).

Risk flags:
- [REVISIT] User's perception of "unified theme" may diverge from objective Stylix behavior; visual audit is the arbiter.

---

### Phase 5 — Future Work (Out of immediate scope)
- Adopt `disko` to replace `hardware-configuration.nix`.
- Parameterize hardware-specific fragilities (keyboard name, monitor names) into a host-level attribute set so `g14.nix` provides them and `desktop.nix` consumes them — would also let `desktop.nix` work on a future machine.
- Consider migrating from `hyprshot` to `grimblast` or `grim+slurp+swappy` for richer screenshot workflows.

---

## 7. Implementation Management

**Sequencing (dependency graph):**

```
wallpaper.png  ──┐
rofi package   ──┼──→ Phase 1 build success ──→ Phase 2 restructure ──→ Phase 3 scripts ──→ Phase 4 themes
HM conflicts   ──┤
swayosd choice ──┘
```

Phase 1 is a single atomic checkpoint — all four items land in one rebuild. Splitting risks half-broken intermediate states.

**Ownership:** Single owner (the user). No team. No coordination cost.

**Critical path:** Phase 1 → Phase 2. Phase 3 is verifiable independently after Phase 2 settles. Phase 4 is observational and can run loosely.

**Integration points:**
- `profiles/dev.nix` is the only file outside `desktop/` that touches the desktop module. Removing `desktop.tools` from its composition is a coordination point — must happen in the same commit as the package relocation.
- `common.nix` imports `homeModules.desktop` — if `desktop.nix` fails to evaluate, the whole user environment is unbuildable. Phase 1 changes are therefore "switch on the first try" critical.

**Breaking changes:**
- [BREAKING] Renaming `homeModules.theme` → `homeModules.stylix` if any consumer imports the old name. Search-and-replace required before commit.
- [BREAKING] Deletion of individual `homeModules.dunst`, `homeModules.hypridle`, etc. — these were already consolidated; confirm no profile still imports them.
- [BREAKING] Removing `lib.pkgsets.desktop.tools` — `profiles/dev.nix` must drop the reference simultaneously.

---

## 8. Validation & Testing Strategy

| Layer | Test Type | What it verifies |
|---|---|---|
| Nix evaluation | `just check` (`nix flake check` + `alejandra --check`) | Flake evaluates, formatting consistent |
| Module composition | `nh os build` | Full build artifact produced without activation |
| Native config syntax | `hyprctl reload` (Hyprland), Waybar journal grep, dunst restart | Each program parses its config without error |
| Theme injection | Post-build grep of activated files for `@.*@` patterns | No unsubstituted placeholders reach runtime |
| Script output schemas | Manual invocation in terminal | JSON shape matches Waybar's expectations |
| Keybind dispatch | Hyprland keybind smoke test | Every bind in hyprland.conf produces its effect |
| Theme coherence | Visual inspection across 6+ apps | One palette, no fights |

**Architecture fitness functions (recommended):**

1. **Placeholder completeness check** — A shell/nu one-liner in the `justfile` that:
   - Reads every `.conf`/`.css`/`.rasi` file in `desktop/`.
   - Extracts `@...@` tokens.
   - Compares against the `placeholders` attrset (parsed from `desktop.nix`).
   - Fails if any token is unresolved.
   This catches missing placeholder declarations at lint time, not at runtime.

2. **No-orphan-module check** — `rg "homeModules\.\w+"` across the repo; any module exposed but never imported is dead code.

3. **Package consumer tracking** — `rg "lib\.pkgsets\.\w+\.\w+"` to confirm every package group has at least one consumer.

**Local dev validation (per change):**
- Run `just check` (must pass).
- Run `just build` (must succeed; doesn't activate).
- Only then run `just switch`.
- After switch, run a smoke-test script that exercises each keybind via `hyprctl dispatch`.

**Observability strategy:**
- Hyprland: `tail -f ~/.local/share/hyprland/hyprland.log` during testing.
- Waybar: `journalctl --user -u waybar -f`.
- Stylix: enable `stylix.enable` debug if needed; otherwise inspect generated files under `/nix/store/.../config/`.
- Scripts: stderr is the channel; redirect Waybar's stderr to a file during debugging.

**Script JSON schemas (contracts to enforce):**

| Script | Mode | Required keys | Notes |
|---|---|---|---|
| `kbd-layout` | `--get` | `text`, `tooltip` | `text` ∈ {"US", "MX", "?"} |
| `kbd-mic` | `--get-status` | `text`, `tooltip`, `class` | `class` ∈ {"muted", ""} |
| `kbd-performance` | `--get` | `text`, `tooltip`, `class` | `class` ∈ {"quiet","balanced","performance","unknown"} |

A Waybar module fed a JSON missing a required key silently displays empty — this is the most common failure mode.

---

## 9. Open Questions & Risks

**Unknowns to resolve during Phase 1:**
- Does `services.swayosd.enable` exist in HM as of nixos-25.11? Verify before removing the manual systemd unit.
- Does the `programs.waybar` module actually conflict with `home.file."./config/waybar/..."`, or does HM tolerate it? The current build error (if there is one) is the empirical answer.

**External dependencies carrying risk:**
- Stylix `release-25.11` branch tracking — if Stylix gates a breaking option change on a minor release bump, `stylix.nix` may need adjustment.
- Hyprland config syntax churn — Hyprland is on a fast release cadence. Native `.conf` reduces but doesn't eliminate breakage.
- `asusctl` output format — `kbd-backlight`/`kbd-performance` parse human-readable output, not a machine API.

**To prototype before committing further:**
- Validate Phase 1 on a single rebuild before doing Phase 2 work. The HM-conflict resolution is the highest-risk single decision; if dropping `programs.waybar.enable` doesn't fix the Waybar error, the diagnosis was wrong and the spec needs revision.

**Hard-to-reverse decisions:**
- Renaming `homeModules.theme` → `homeModules.stylix` is trivially reversible (rename back).
- Deleting `volume.nu` is reversible from git.
- No decisions in this plan are git-irreversible.

---

## Appendix A — Reference: Final `desktop.nix` Composition

What `desktop.nix` should contain after all phases (described, not coded):

1. Module header importing `inputs.stylix.homeModules.stylix` and `inputs.self.homeModules.stylix` (the local one with palette).
2. `let`-binding of `placeholders` attrset and `applyTheme` function.
3. HM enables that don't conflict: `services.swayosd.enable`, `wayland.windowManager.hyprland.enable` (the only one whose `extraConfig` mechanism cleanly accepts injected text).
4. `home.file` block writing each native config via `applyTheme (readFile ./X)` or raw `readFile ./X` as appropriate. Includes symlinks for all `scripts/*.nu` to `~/.local/bin/`.
5. `home.packages` listing what was previously in `desktop.tools` (now inline) plus rofi.
6. No inline CSS, no inline bash, no Stylix block (moved to `stylix.nix`).

Total expected size: ~80–100 lines, down from current ~220.

---

End of spec.