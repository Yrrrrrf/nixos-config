# Helix Track 2 — Modularization & Language Coverage Spec

**Status:** Specification, ready for implementation.
**Prerequisite:** Track 1 (CUDA consolidation) committed.
**Successor:** Track 3 (tool dedup) and Phase B (dendritic migration).
**Audience:** the maintainer of `nixos/` flake, post-NVIDIA cleanup phase.
**Verification primitive:** `hx --health <language>` per language.

---

## 0. Executive Summary

This spec restructures the helix editor configuration from a single monolithic `home/modules/editor/helix.nix` file into a directory of per-language modules. In the same pass, it fixes five outstanding language-server bugs identified in the audit, swaps four legacy tools for their modern Rust-aligned equivalents, and extends language coverage by six languages that were previously unconfigured. The end state is a helix module where every supported language is a self-contained vertical slice — its language entry, its language servers, its formatter, and its package dependencies all live in one file. Adding a new language is one new file; removing one is one deletion. The result is reproducible, diffs cleanly, satisfies the maintainer's stated philosophy of preferring Rust-written, modern, strict tools over the most-used ones, and pre-shapes the helix module for the upcoming dendritic migration (Phase B) where each per-language file can be promoted to a top-level module nearly as-is.

---

## 1. Context & Constraints

### 1.1 Project context

- Single-maintainer NixOS flake on an Asus ROG Zephyrus G14 (`g14`) host.
- Source layout uses path-significant grouping: `home/`, `system/`, `host/`, `templates/`. Helix lives under `home/modules/editor/`.
- Track 1 (CUDA consolidation) is committed. NVIDIA driver layer is clean. CUDA application stack lives in a single `system/cuda.nix`.
- Helix version detected on host: `25.07.1`. Modern enough for all features this spec relies on (file-type globs, `formatter` block as `{ command, args }`, multi-language-server entries per language).
- Maintainer philosophy (relevant subset): prefer Rust over C/Go/JS where mature; prefer modular over monolithic; prefer reproducible (Nix-managed) over opaque (rustup, npx, pipx); prefer newer-and-stricter over most-used-and-permissive.

### 1.2 Goals

- **Primary:** every language the maintainer actually uses produces a clean `hx --health` row — language server, formatter, treesitter parser, and indent queries all show check marks.
- **Secondary:** the helix module is small enough per file that reading any single file fits on one screen, and adding a new language is a single new file under `langs/`.
- **Tertiary:** every change leaves a clear migration trail toward Phase B (dendritic), where the same per-language files can be promoted to top-level flake-parts modules with minimal modification.

### 1.3 Done means

- `nix flake check` passes.
- `sudo nixos-rebuild switch --flake .#g14` succeeds.
- `hx --health` for each of the 22 covered language entries shows check marks for the columns that apply (LSP, Formatter, Highlight, Textobject, Indent — Debug Adapter excluded; not in scope).
- Five bugs from the audit are silent — no longer reproducible.
- Six new languages (clangd-backed C/C++, just, markdown, yaml, lua, nix-pinned rust-analyzer) report green.
- Sample files under `home/modules/editor/helix/samples/` open in helix with their LSP attached, formatter callable, and an intentionally-introduced error surfaces a diagnostic.

### 1.4 Architectural rules in force

- **Nix-pinned over external package managers** — every LSP and formatter referenced by helix must resolve to a `pkgs.<attr>` derivation, not to a tool installed by `rustup`, `npm`, `pipx`, or `cargo install`.
- **Single source of truth per concern** — a tool's package is declared in exactly one place: the language file that uses it.
- **No imperative side-channels** — no `LD_LIBRARY_PATH` injections, no symlink shenanigans, no `home.activation` scripts to wire up LSPs.
- **Treesitter and indent come from helix's own runtime** — not separately managed; the helix package provides them. This spec does not touch tree-sitter grammars.

### 1.5 Out of scope

- Phase B (dendritic migration). The structure is *prepared* for it but no `flake-parts` or `import-tree` plumbing is added here.
- The `templates/` directory. No `templates/helix-test/` shell. Sample files live inside the helix module itself.
- Track 3 (tool dedup — `neofetch`, `tree`, `jq`/`jaq`, `fzf`/`skim`). Independent track.
- Debug adapters. Helix's `--health` reports a Debug Adapter column; this spec does not configure DAP for any language. Future track.
- Rust toolchain overlay (fenix or rust-overlay). Spec uses `pkgs.rust-analyzer` directly; overlay-based pinning of cargo+rustc+ra as a unit is recorded as future work but not done here.

### 1.6 Assumptions

- **[ASSUMPTION]** `pkgs.ty`, `pkgs.markdown-oxide`, `pkgs.dprint`, `pkgs.biome`, `pkgs.alejandra`, `pkgs.just-lsp` all resolve in the maintainer's pinned `nixpkgs` channel. Verified by maintainer via `nix search`.
- **[ASSUMPTION]** The maintainer's `nixpkgs` channel is recent enough that `pkgs.nixfmt-rfc-style` exists (it is in unstable and recent stable channels).
- **[ASSUMPTION]** No other module in the flake declares conflicting `programs.helix.languages` entries. Helix's languages config is additive across modules in home-manager but the audit suggests all helix config is currently centralized.
- **[ASSUMPTION]** The maintainer accepts losing pyright in exchange for `ty`. `ty` is in beta (0.0.x versioning); this carries small risk that an edge case won't be caught. Acceptable per stated philosophy.

---

## 2. Architecture Overview

### 2.1 Layered structure

The helix module decomposes into three layers, each with a single responsibility:

- **Editor layer** — the helix program enable, theme selection, keybinding overrides, and any non-language editor settings (line numbers, soft-wrap, cursor shape, status line). This layer knows nothing about languages.
- **Language registry layer** — one file per language (or per family of languages that share a backing tool). Each file is a self-contained vertical slice: it adds the helix `[[language]]` entry, the `[language-server.*]` entries, optional `[language.formatter]`, and the `home.packages` additions required for those tools to resolve. No language file knows about another language.
- **Verification layer** — a `samples/` directory living inside the helix module, with one minimal source file per configured language. Used for interactive verification (`hx samples/sample.<ext>`) after each rebuild.

### 2.2 Component diagram

```
                  ┌─────────────────────────────────┐
                  │ home-manager configuration      │
                  └────────────────┬────────────────┘
                                   │ imports
                                   ▼
                  ┌─────────────────────────────────┐
                  │ home/modules/editor/helix/      │
                  │  default.nix                    │
                  │   ├─ programs.helix.enable      │
                  │   ├─ theme + keybinds           │
                  │   └─ imports settings + langs   │
                  └────────────────┬────────────────┘
                                   │
                  ┌────────────────┴────────────────┐
                  │                                 │
                  ▼                                 ▼
      ┌───────────────────────┐     ┌──────────────────────────────┐
      │ settings.nix          │     │ langs/default.nix            │
      │  programs.helix       │     │  imports every langs/*.nix   │
      │    .settings block    │     └──────────┬───────────────────┘
      └───────────────────────┘                │
                                               │ imports
                          ┌────────────────────┼─────────────────────────────┐
                          ▼                    ▼                             ▼
          ┌─────────────────┐  ┌─────────────────────┐    ┌──────────────────────┐
          │ langs/rust.nix  │  │ langs/python.nix    │... │ langs/web.nix        │
          │  rust-analyzer  │  │  ty + ruff          │    │  ts/js/json/css/html │
          │  rustfmt        │  │  ruff format        │    │  /svelte (grouped)   │
          │  home.packages  │  │  home.packages      │    │  home.packages       │
          └─────────────────┘  └─────────────────────┘    └──────────────────────┘

      ┌────────────────────────────────────────────────────────────────────────┐
      │ home/modules/editor/helix/samples/                                     │
      │   sample.rs, sample.py, sample.c, sample.cpp, sample.ts, sample.json,  │
      │   sample.css, sample.html, sample.svelte, sample.toml, sample.nix,     │
      │   sample.sql, sample.sh, sample.lua, sample.go, sample.s, sample.asm,  │
      │   sample.kt, hyprland.conf, sample.typ, Justfile, sample.md,           │
      │   sample.yaml                                                          │
      └────────────────────────────────────────────────────────────────────────┘
```

### 2.3 Core domain vs supporting

- **Core domain:** `langs/` — this is where language coverage lives. The spec's reason to exist.
- **Supporting:** `default.nix` and `settings.nix` — wire helix on, set theme, set editor preferences. These are scaffolding.
- **Verification artifacts:** `samples/` — not consumed by the running system, used by the maintainer to verify behavior.

---

## 3. Design Patterns & Code Standards

### 3.1 Pattern 1 — Registry, one file per registered entry

**Pattern chosen:** **Module Registry**, where each registered item (a language or a tightly-coupled family of languages) is a separate file imported by an aggregator.

**Why this pattern:** the alternative is a single growing monolith where 22 languages crowd one file. With a registry, each language is independent: changing the python toolchain touches only `langs/python.nix`. Three-year horizon: when typst tooling changes (it changes fast), or when ty graduates from 0.0.x to 1.0, the diff is one file. Five-year horizon: when languages get added or removed from the maintainer's stack, the registry tells the truth — what's present is what's used. Ten-year horizon: this is the same shape as the dendritic Phase B "language registry" pattern, so Phase B becomes a near-mechanical lift.

**How it's applied:** `langs/default.nix` imports every sibling file under `langs/`. Each sibling exports a home-manager module fragment that contributes:
- exactly one or more `programs.helix.languages.language` entries (the `[[language]]` block in TOML terms),
- one or more `programs.helix.languages.language-server.*` entries (one per LSP referenced by those languages),
- the matching `home.packages` additions so the LSP and formatter binaries resolve on `$PATH`.

**Standards to enforce:**
- A language file must not modify `programs.helix.settings`. If it would, the right place is `settings.nix`.
- A language file must not declare `home.packages` for tools it does not reference in its language-server or formatter blocks. No drive-by package additions.
- A language file is named after the language, not after the LSP. `python.nix`, not `ty.nix` or `ruff.nix`.
- Multi-language families that share the *same* backing tool live together: `c-based.nix` (C and C++ both use clangd from `clang-tools`), `asm.nix` (gas and nasm both use asm-lsp). Languages that share a backing tool but are conceptually distinct families do *not* group: TypeScript and Svelte both use `typescript-language-server` indirectly but live in separate concepts; both happen to be in `web.nix` for a different reason (see §3.2).

### 3.2 Pattern 2 — Selective grouping for the web stack and the shell stack

**Pattern chosen:** **Bounded Aggregate**, applied selectively to two domains where pure per-language splitting would proliferate small files for one logical concern.

**Why this pattern:** the web stack (TypeScript, JavaScript, JSON, CSS, HTML, Svelte) shares the same formatter binary (`biome` for the four it covers, `prettier` for the rest) and is updated together when a JS-ecosystem change happens. Splitting them into six tiny files would create six diffs every time the team-of-one bumps biome. Same logic for shell (`bash`, `lua`) — different LSPs but configured together because they're "things that look like scripts." Three-year horizon: web and shell stacks change as units. Splitting them costs more than it saves.

**How it's applied:** two files — `web.nix` and `shell.nix` — each declare multiple `[[language]]` entries and the union of all `language-server` and `home.packages` they need. All other languages get their own file.

**Standards to enforce:**
- The grouping list is fixed: `web.nix` covers exactly `{typescript, javascript, json, css, html, svelte}`. `shell.nix` covers exactly `{bash, lua}`. Adding a new web-flavored language (e.g., Vue) goes in `web.nix`; adding a new shell-flavored language (e.g., zsh-mode) goes in `shell.nix`.
- If `web.nix` exceeds ~120 lines, that is the trigger to split it: at that point per-language files become cheaper than the aggregate.
- A grouped file must still organize internally by language: each language's `[[language]]` entry lives next to its `language-server` entries, not interleaved with other languages.

### 3.3 Pattern 3 — Tool-package coupling

**Pattern chosen:** **Vertical Slice**, where the LSP package, the formatter package, the helix language entry, and the helix language-server entry all live in the same file.

**Why this pattern:** the alternative is "all packages in `packages.nix`, all language config in `languages.nix`, all formatters in `formatters.nix`" — the horizontal-slice approach. Horizontal slicing means changing one language touches three files; vertical slicing means changing one language touches one file. Three-year horizon: the maintainer's memory is the limiting resource. One file per change is the minimum cognitive load.

**How it's applied:** every `langs/<name>.nix` declares its `home.packages` additions inline. There is no central package list in the helix module. Cross-language packages (e.g., if both python's ruff and another language wanted `dprint`) would each declare it; Nix deduplicates derivations automatically. No coordination needed.

**Standards to enforce:**
- A package added to `home.packages` in a language file must be referenced by that file's helix config. No "while you're here, also add X."
- If a tool is genuinely shared across two language files (e.g., `prettier` if both `web.nix` and another file used it), each file declares it independently. Nix collapses duplicates. No "shared.nix" file.

### 3.4 Pattern 4 — Verification by sample

**Pattern chosen:** **Smoke Test by Artifact**, where a directory of minimal source files exists for the explicit purpose of opening them in helix and watching the LSP attach.

**Why this pattern:** helix has no automated test harness for a configured-helix-from-the-outside. The closest tool is `hx --health <language>`, which checks that the binaries resolve but does not exercise the language server end-to-end. Sample files close that gap at near-zero cost: opening one file per language, looking at `:lsp-workspace-stats` and triggering `:format`, takes seconds and catches the class of bug that `--health` misses (e.g., LSP binary present but misconfigured args, formatter present but wrong invocation pattern).

**How it's applied:** `home/modules/editor/helix/samples/` contains one source file per configured language. Each sample is short (5–15 lines), syntactically valid, and contains exactly one intentional issue that should surface as a diagnostic — a misspelled identifier, a type mismatch, an undefined variable. The exception is languages where diagnostics are scoped (e.g., `hyprlang.conf` may not flag a typo; the sample then only verifies LSP attachment).

**Standards to enforce:**
- Samples live inside the helix module so they're part of the same diff that adds the language.
- A new language added to `langs/` must come with its sample file in the same commit. No exceptions.
- Samples are not run automatically; verification is interactive. `hx --health` is the automated layer.

### 3.5 Cross-cutting standards

- **Naming:** files are lowercase, hyphens permitted (`c-based.nix`). Helix language names follow helix's own canonical names (`gas` not `asm`, `typescript` not `ts`).
- **Imports direction:** `default.nix` imports `langs/`. `langs/` imports nothing from outside its directory. Nothing imports `samples/` — they are runtime artifacts.
- **No circular references:** a language file must not refer to another language file by path or by attribute.
- **Comments:** each language file opens with a one-line comment stating what languages it covers and what tools it brings. No further comments needed unless explaining a workaround.
- **Error handling:** if a referenced package does not resolve, the build fails at evaluation time. This is the desired behavior — it surfaces broken references immediately. Do not use `lib.optional` or conditional package inclusion to hide missing tools.

---

## 4. Component Map & Directory Structure

### 4.1 Full proposed tree

```
home/modules/editor/
└── helix/
    ├── default.nix
    ├── settings.nix
    ├── langs/
    │   ├── default.nix
    │   ├── rust.nix
    │   ├── python.nix
    │   ├── c-based.nix
    │   ├── asm.nix
    │   ├── web.nix
    │   ├── shell.nix
    │   ├── nix.nix
    │   ├── toml.nix
    │   ├── yaml.nix
    │   ├── sql.nix
    │   ├── markdown.nix
    │   ├── typst.nix
    │   ├── just.nix
    │   ├── hyprlang.nix
    │   ├── kotlin.nix
    │   └── go.nix
    └── samples/
        ├── sample.rs
        ├── sample.py
        ├── sample.c
        ├── sample.cpp
        ├── sample.s
        ├── sample.asm
        ├── sample.ts
        ├── sample.js
        ├── sample.json
        ├── sample.css
        ├── sample.html
        ├── sample.svelte
        ├── sample.sh
        ├── sample.lua
        ├── sample.nix
        ├── sample.toml
        ├── sample.yaml
        ├── sample.sql
        ├── sample.md
        ├── sample.typ
        ├── Justfile
        ├── hyprland.conf
        ├── sample.kt
        └── sample.go
```

### 4.2 Per-component contracts

#### `helix/default.nix`
- **Responsibility:** enable helix, set the theme, set keybindings, import the language registry and the settings module.
- **Interfaces it exposes:** the home-manager `programs.helix` enable + theme + keybindings options as set values. Imports `./settings.nix` and `./langs`.
- **Dependencies it consumes:** `pkgs.helix` (transitively, via `programs.helix.enable`).
- **Must NOT do:** declare any `[[language]]` entry. Declare any `language-server` entry. Add any package related to a language to `home.packages`.

#### `helix/settings.nix`
- **Responsibility:** declare the contents of `programs.helix.settings` — line numbers, soft-wrap, cursor shape per editor mode, status line content, file picker config, gutter config, anything in the `[editor]` block of helix's config.
- **Interfaces it exposes:** sets `programs.helix.settings.editor.*` keys.
- **Dependencies it consumes:** none.
- **Must NOT do:** touch `programs.helix.languages` in any way. Touch `home.packages`.

#### `helix/langs/default.nix`
- **Responsibility:** import every sibling file under `langs/`. Pure aggregator.
- **Interfaces it exposes:** an `imports` list referencing every sibling.
- **Dependencies it consumes:** the sibling files.
- **Must NOT do:** declare any helix config of its own. Add packages.

#### `helix/langs/rust.nix`
- **Responsibility:** declare the `rust` language entry, the `rust-analyzer` language-server entry, and add `pkgs.rust-analyzer` and `pkgs.rustfmt` to `home.packages`. Set the rust formatter to invoke `rustfmt`.
- **Interfaces it exposes:** one `[[language]]` entry for rust, one `language-server.rust-analyzer` entry, two package additions.
- **Dependencies it consumes:** `pkgs.rust-analyzer`, `pkgs.rustfmt`.
- **Must NOT do:** mention any other language. Add tools that aren't rust-specific.
- **Migration note:** this file *replaces* the maintainer's reliance on `rustup component add rust-analyzer`. After this lands, the rustup-managed rust-analyzer becomes dead weight on `$PATH` (the nix-managed one takes precedence by being declared first or by `rustup`'s installation living elsewhere).

#### `helix/langs/python.nix`
- **Responsibility:** declare the `python` language entry with two language servers (`ty` for types, `ruff` for lint+format diagnostics), set the formatter to `ruff format`, add `pkgs.ty` and `pkgs.ruff` to `home.packages`.
- **Interfaces it exposes:** one `[[language]]` entry for python with `language-servers = ["ty", "ruff"]`, two `language-server` entries (`ty` invoking `ty server`, `ruff` invoking `ruff server`), one formatter entry pointing at `ruff format -`.
- **Dependencies it consumes:** `pkgs.ty`, `pkgs.ruff`.
- **Must NOT do:** declare pyright, ruff-lsp, basedpyright, mypy, or any non-Astral python tool. Add `pkgs.python3` itself (that is a different concern, lives elsewhere).
- **Migration note:** this fixes audit Bug #3 (deprecated `ruff-lsp`) and intentionally replaces pyright with ty per the maintainer's choice. ty is in beta; if a sharp edge surfaces, the rollback is a one-file revert plus reinstating `pkgs.pyright`.

#### `helix/langs/c-based.nix`
- **Responsibility:** declare both `c` and `cpp` language entries, the shared `clangd` language-server entry, set both formatters to `clang-format`, add `pkgs.clang-tools` to `home.packages`.
- **Interfaces it exposes:** two `[[language]]` entries (c, cpp), one `language-server.clangd` entry, one package addition.
- **Dependencies it consumes:** `pkgs.clang-tools` (provides both `clangd` and `clang-format` binaries).
- **Must NOT do:** declare opencl or other clangd-using languages without explicit decision (currently out of scope).
- **Migration note:** addresses audit's missing-package finding for clangd.

#### `helix/langs/asm.nix`
- **Responsibility:** declare both `gas` and `nasm` language entries, the shared `asm-lsp` language-server entry, add `pkgs.asm-lsp` to `home.packages`.
- **Interfaces it exposes:** two `[[language]]` entries (gas, nasm), one `language-server.asm-lsp` entry.
- **Dependencies it consumes:** `pkgs.asm-lsp`.
- **Must NOT do:** declare a generic `asm` entry (that name is helix's old, non-functional alias and is the audit Bug #2 being fixed).
- **Migration note:** the maintainer's current config has `name = "asm"`. The fix is to delete that and add `name = "gas"` and `name = "nasm"` separately. `hx --health` confirms both already work today (asm-lsp is installed) — the fix is the entry name, not the package.

#### `helix/langs/web.nix`
- **Responsibility:** declare the six web languages (typescript, javascript, json, css, html, svelte), wire each to its appropriate LSP (`typescript-language-server` for ts/js, `vscode-json-language-server` for json, `vscode-css-language-server` for css, `vscode-html-language-server` for html, `svelteserver` for svelte), set the formatter to `biome` for ts/js/json/css and to `prettier` for html/svelte.
- **Interfaces it exposes:** six `[[language]]` entries, five `language-server` entries (one per LSP, with `typescript-language-server` referenced by both ts and js), package additions for `pkgs.typescript-language-server`, `pkgs.vscode-langservers-extracted`, `pkgs.svelte-language-server`, `pkgs.biome`, `pkgs.nodePackages.prettier`.
- **Dependencies it consumes:** the five packages above.
- **Must NOT do:** declare yaml (it's not web; it lives in `yaml.nix` so it can be referenced from non-web contexts cleanly). Declare graphql or vue (not in current scope; future additions welcome).
- **Internal organization:** the file orders entries as `typescript`, `javascript`, `json`, `css`, `html`, `svelte`, with each language's `[[language]]` entry adjacent to its `language-server` entry. Formatters are inline with their language.

#### `helix/langs/shell.nix`
- **Responsibility:** declare `bash` and `lua` language entries, wire each to its LSP (`bash-language-server` and `lua-language-server`), set formatters (`shfmt` for bash, `stylua` for lua), add the four packages.
- **Interfaces it exposes:** two `[[language]]` entries, two `language-server` entries, four package additions.
- **Dependencies it consumes:** `pkgs.bash-language-server`, `pkgs.shfmt`, `pkgs.lua-language-server`, `pkgs.stylua`.
- **Must NOT do:** declare zsh or fish (different shells, different tools, separate decision).

#### `helix/langs/nix.nix`
- **Responsibility:** declare the `nix` language entry, the `nil` language-server entry, set formatter to `alejandra`, add `pkgs.nil` and `pkgs.alejandra` to `home.packages`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.nil` entry, two packages.
- **Dependencies it consumes:** `pkgs.nil`, `pkgs.alejandra`.
- **Must NOT do:** declare `nixd` or `nixpkgs-fmt` or `nixfmt-rfc-style`. The choice of nil + alejandra is the spec's deliberate Rust-aligned pair.
- **Migration note:** this fixes audit Bug #5 (drop `nixpkgs-fmt`). The maintainer's current `hx --health` shows `nix` formatted by `nixpkgs-fmt`; the post-Track-2 health line should show `alejandra` instead.

#### `helix/langs/toml.nix`
- **Responsibility:** declare the `toml` language entry, the `taplo` language-server entry, set formatter to `taplo fmt`, add `pkgs.taplo`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.taplo` entry, one package.
- **Dependencies it consumes:** `pkgs.taplo`.
- **Must NOT do:** declare `tombi` (newer alternative; deferred until taplo shows a specific shortcoming).

#### `helix/langs/yaml.nix`
- **Responsibility:** declare the `yaml` language entry, the `yaml-language-server` entry, set formatter to `prettier` (no Rust-aligned YAML formatter is mature enough yet), add `pkgs.yaml-language-server` and confirm `pkgs.nodePackages.prettier` is available (it is, via `web.nix` — Nix dedups).
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.yaml-language-server` entry, one package addition (prettier already present elsewhere).
- **Dependencies it consumes:** `pkgs.yaml-language-server`. Implicitly `pkgs.nodePackages.prettier` (via `web.nix`).
- **Must NOT do:** declare ansible-language-server (separate concern, not in current scope).

#### `helix/langs/sql.nix`
- **Responsibility:** declare the `sql` language entry, the `sqls` language-server entry, add `pkgs.sqls`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.sqls` entry, one package.
- **Dependencies it consumes:** `pkgs.sqls`.
- **Must NOT do:** set a formatter (sqls handles formatting via LSP commands, not as an external formatter binary).

#### `helix/langs/markdown.nix`
- **Responsibility:** declare the `markdown` language entry, the `markdown-oxide` language-server entry, set formatter to `dprint fmt --stdin md`, add `pkgs.markdown-oxide` and `pkgs.dprint`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.markdown-oxide` entry, two packages.
- **Dependencies it consumes:** `pkgs.markdown-oxide`, `pkgs.dprint`.
- **Must NOT do:** declare `marksman` (the F#/.NET alternative; rejected per philosophy).

#### `helix/langs/typst.nix`
- **Responsibility:** declare the `typst` language entry with the `file-types` array correctly placed inside the `[[language]]` block (audit Bug #1 fix), the `tinymist` language-server entry, set formatter to `typstyle`, add `pkgs.tinymist` and `pkgs.typstyle`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.tinymist` entry, two packages.
- **Dependencies it consumes:** `pkgs.tinymist`, `pkgs.typstyle`.
- **Must NOT do:** repeat the Bug #1 anti-pattern of putting `file-types` inside the language-server block.
- **Migration note:** the audit's Bug #1 was a silent failure — `.typ` files weren't detected as typst, so tinymist never attached. The fix here is structural; a sample file (`samples/sample.typ`) verifies the fix took.

#### `helix/langs/just.nix`
- **Responsibility:** declare the `just` language entry with `file-types` covering `Justfile` and `*.just`, the `just-lsp` language-server entry, set formatter to `just --fmt --unstable`, add `pkgs.just-lsp` and ensure `pkgs.just` is in `home.packages` (probably already is via the maintainer's existing `cli.nix`; declare again here, Nix dedups).
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.just-lsp` entry, two packages.
- **Dependencies it consumes:** `pkgs.just-lsp`, `pkgs.just`.
- **Must NOT do:** declare any other build-tool language.

#### `helix/langs/hyprlang.nix`
- **Responsibility:** declare the `hyprlang` language entry with **scoped `file-types`** (audit Bug #4 fix) — only matching `hyprland.conf`, `hyprlock.conf`, `hypridle.conf`, `hyprpaper.conf`, and `hypr/*.conf`, not all `*.conf` files. Wire to `hyprls` LSP, add `pkgs.hyprls`.
- **Interfaces it exposes:** one `[[language]]` entry with a glob-restricted `file-types` array, one `language-server.hyprls` entry, one package.
- **Dependencies it consumes:** `pkgs.hyprls`.
- **Must NOT do:** match all `.conf` files. Match nginx, alsa, or anything else that isn't hyprland.
- **Migration note:** the audit's Bug #4 was scope creep — `hyprls` was attaching to every `.conf` file system-wide. The fix uses helix's glob syntax in `file-types` to scope down. Verify by opening a non-hyprland `.conf` file and confirming `:lsp-workspace-stats` shows no LSP attached.

#### `helix/langs/kotlin.nix`
- **Responsibility:** declare the `kotlin` language entry, the `kotlin-language-server` entry, set formatter to `ktlint`, add `pkgs.kotlin-language-server` and `pkgs.ktlint`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.kotlin-language-server` entry, two packages.
- **Dependencies it consumes:** `pkgs.kotlin-language-server`, `pkgs.ktlint`.
- **Must NOT do:** declare gradle, java, or other JVM languages (not in scope).

#### `helix/langs/go.nix`
- **Responsibility:** declare the `go` language entry, the `gopls` language-server entry, leave formatter to gopls's built-in `gofmt` invocation (no separate formatter package needed; `gofmt` ships with `pkgs.go`), add `pkgs.gopls`.
- **Interfaces it exposes:** one `[[language]]` entry, one `language-server.gopls` entry, one package.
- **Dependencies it consumes:** `pkgs.gopls`. `pkgs.go` is implicitly required for `gofmt` to exist; verify it's present in the maintainer's existing package set, otherwise declare here.
- **Must NOT do:** declare `gomod`, `gowork`, `gotmpl` separately — helix's `--health` shows these are already handled by gopls when go is configured. They don't need explicit entries.

#### `helix/samples/`
- **Responsibility:** house the per-language sample files used for interactive verification.
- **Interfaces it exposes:** none. Files exist on disk; opened by the maintainer with `hx samples/<file>`.
- **Dependencies it consumes:** none directly. Indirectly: the LSPs and formatters declared by sibling `langs/` files must be available for the samples to demonstrate working behavior.
- **Must NOT do:** be referenced by any `imports` chain. Be required for the system to build. The samples are runtime artifacts.

---

## 5. Trade-off Analysis

### Decision 1 — Module decomposition strategy

```
DECISION: How to split the helix language config across files
OPTIONS CONSIDERED:
  A. Single monolithic helix.nix — one file, all 22 languages inline.
     pros: nothing to import, no aggregator file, fewest files in the tree.
     cons: 400+ line file, every language change is a diff in the same file,
       merge conflicts (even single-maintainer; rebases) become painful, no
       natural boundary for Phase B promotion.
  B. Pure per-language split — one file per language, 22 files in langs/.
     pros: maximum modularity, each file is the smallest possible unit, Phase B
       promotion is mechanical.
     cons: 22 small files for what is sometimes 5-line content (asm.nix would
       have one entry that just lists gas and nasm), directory listing noise,
       trivial changes to the web stack become 6 separate diffs.
  C. Hybrid — per-language split for everything except web and shell, which
     stay grouped because their members change together.
     pros: keeps the modular philosophy where it pays, accepts pragmatic
       grouping where pure splitting would fragment a coherent concern.
     cons: the rule "split per language except where grouped" requires the
       maintainer to remember which is which; mitigated by §3.2's standards.
CHOSEN: C (Hybrid).
REASON: matches the maintainer's stated preference verbatim. Single-file is
  ruled out by the modularity rule; pure per-language is overkill for the web
  stack which gets updated as a unit. The hybrid is the empirical sweet spot.
REVISIT IF: web.nix exceeds ~120 lines (then split it), or a third group emerges
  that wants its own aggregate file.
```

### Decision 2 — Python type checker

```
DECISION: Which type checker for Python in helix
OPTIONS CONSIDERED:
  A. pyright — current incumbent, mature, slow startup, JS-based (Pyright
     binary ships embedded Node).
     pros: most-tested, most-features, every Python guide assumes it.
     cons: slow startup (~600ms cold), JS runtime lurking, not Rust-aligned.
  B. basedpyright — community fork of pyright, faster startup, drop-in.
     pros: pyright compatibility plus speed, actively maintained.
     cons: still derived from pyright, still TypeScript-based at the core.
  C. ty — Astral's Rust-based type checker, beta, designed for LSP from the
     ground up.
     pros: 10-100x faster than pyright, Rust-aligned, shares the Astral
       toolchain with ruff and uv that the maintainer already uses, fits
       the "newer and stricter" philosophy.
     cons: 0.0.x versioning, beta status, 1.0 not until 2026, may have
       behavior gaps on advanced typing patterns.
CHOSEN: C (ty).
REASON: matches the maintainer's stated philosophy unambiguously. The Astral
  toolchain (uv + ruff + ty) is the consistent answer; choosing anything else
  for types breaks the consistency. Beta risk is acceptable for a single-
  maintainer personal flake; if a sharp edge surfaces, the rollback is a
  one-line swap in python.nix.
REVISIT IF: ty's beta drags past mid-2026 with show-stopping bugs, or the
  maintainer hits a typing pattern ty can't analyze and pyright can.
```

### Decision 3 — JavaScript/TypeScript LSP

```
DECISION: Which LSP for the web stack
OPTIONS CONSIDERED:
  A. typescript-language-server (current) + biome as formatter only.
     pros: standard, mature, every IDE assumes it, biome handles fmt+lint
       in Rust speed without losing semantic LSP features.
     cons: tsserver is itself a Node binary; not Rust-aligned. Two tools
       per file (tsserver for semantics, biome for fmt+lint).
  B. biome alone, drop tsserver.
     pros: single Rust binary, fastest possible startup.
     cons: biome is not a type-aware LSP. No go-to-definition, no hover-
       with-types, no rename, no autocomplete-from-types. Drops every IDE
       feature that depends on understanding what code means rather than
       how it looks. Net loss of capability.
  C. vtsls — community fork of tsserver, faster, same protocol.
     pros: drop-in for tsserver with measurable speedups.
     cons: still Node-based, still not Rust. Marginal gain for added drift
       from upstream.
CHOSEN: A.
REASON: biome and tsserver are complementary, not competing. Biome replaces
  prettier+eslint, not tsserver. Dropping tsserver costs every type-aware
  IDE feature in exchange for ~30% startup speed on operations the
  maintainer barely notices. Not worth it.
REVISIT IF: Astral or another team ships a Rust-based TypeScript semantic
  LSP with type-aware features (this is rumored as a long-term Astral
  project but not announced).
```

### Decision 4 — Markdown LSP

```
DECISION: Which LSP for Markdown
OPTIONS CONSIDERED:
  A. marksman — most-recommended, F#/.NET implementation, mature.
     pros: most-recommended, well-documented, stable.
     cons: F# means a Mono runtime dependency, slow cold start, not
       Rust-aligned.
  B. markdown-oxide — Rust port inspired by Obsidian's link-following.
     pros: Rust-aligned, single binary, faster startup, good
       cross-document link handling.
     cons: less battle-tested than marksman, smaller user base.
CHOSEN: B (markdown-oxide).
REASON: the maintainer's philosophy is explicit on "newer Rust over most-used."
  Markdown LSP capabilities are narrow enough (hover for links, jump to
  reference, basic outline) that the maturity gap doesn't matter much.
REVISIT IF: markdown-oxide misses a feature the maintainer relies on
  (e.g., wikilinks, embeds), or development stalls.
```

### Decision 5 — Sample location

```
DECISION: Where to put the sample files used for verification
OPTIONS CONSIDERED:
  A. Inside the helix module (home/modules/editor/helix/samples/).
     pros: lives next to the module that needs them, same diff adds
       a language and its sample, no separate flake to manage.
     cons: pollutes the helix module directory with files that aren't
       imported anywhere.
  B. In templates/helix-test/ as a separate flake with its own devShell.
     pros: matches the existing templates/cuda/ pattern, isolates testing,
       could later become a CI-runnable check.
     cons: adds a templates/ entry just for samples, requires an extra
       cd to use, the maintainer explicitly said templates are out of
       scope for this spec.
  C. In a top-level docs/helix-samples/ alongside the audit docs.
     pros: groups all helix-related artifacts.
     cons: docs/ is for documentation; samples are runtime test artifacts,
       different concern.
CHOSEN: A (inside the helix module).
REASON: the maintainer explicitly deferred templates/ work for this spec.
  Putting samples inside the helix module keeps the spec's deliverable
  self-contained — one directory tree, no cross-module coordination.
  Phase B can promote samples/ to a templates/ entry later if desired.
REVISIT IF: the sample collection grows beyond ~30 files, or CI integration
  becomes a goal.
```

---

## 6. Phased Implementation Plan

Track 2 itself decomposes into three sub-phases that are independently committable. Each commit passes `nix flake check` and `sudo nixos-rebuild switch`.

### Phase 2A — Structural lift (no semantic changes)

- **Goal:** decompose the existing monolithic `helix.nix` into the new directory structure with no functional changes. Bugs from the audit remain present in the new structure; they get fixed in 2B. This is purely a "move code around" commit.
- **Components to build:** `helix/default.nix`, `helix/settings.nix`, `helix/langs/default.nix`, plus `langs/` files for every language *currently configured* in the monolith (which excludes ty, just-lsp, markdown-oxide, dprint, biome, alejandra, clang-tools, lua-language-server, marksman, yaml-language-server — those are 2B/2C additions).
- **Dependencies:** Track 1 committed.
- **Exit criteria:** `nixos-rebuild switch` succeeds. `hx --health` output is *byte-identical* to the pre-2A baseline (verify by capturing baseline before starting, diffing after). The maintainer's existing helix workflow is unchanged.
- **Risk flags:** [HIGH RISK] this is the largest single diff in Track 2 by line count. A typo in the import chain breaks the entire helix config. Mitigation: do not delete the original `helix.nix` until 2A passes `nixos-rebuild`; rename it to `helix.nix.bak` first.

### Phase 2B — Bug fixes and tool swaps

- **Goal:** fix the five audit bugs and apply the philosophy-aligned tool swaps. Per-file changes only; no new languages added yet.
- **Components touched:** `langs/typst.nix` (Bug #1: file-types placement), `langs/asm.nix` (Bug #2: gas/nasm split), `langs/python.nix` (Bug #3: ruff-lsp → ruff server, swap pyright → ty), `langs/hyprlang.nix` (Bug #4: scope file-types), `langs/nix.nix` (Bug #5: drop nixpkgs-fmt, switch to alejandra), and the web.nix formatter swap (prettier → biome for the four it covers).
- **Dependencies:** 2A committed.
- **Exit criteria:** `hx --health python` shows `ty` and `ruff` in the LSP column (no more pyright, no more ruff-lsp). `hx --health gas` and `hx --health nasm` both show check marks (the old `asm` row is gone or harmless). `hx --health typst` shows tinymist and typstyle. `hx --health nix` shows `alejandra` as formatter. Opening a non-hyprland `.conf` file does *not* attach hyprls (manual verification).
- **Risk flags:** [REVISIT] ty is in beta. If it crashes on the maintainer's existing Python projects, fall back to basedpyright in a follow-up commit and document.

### Phase 2C — New language additions and verification

- **Goal:** add the six new language coverages (full clang-tools-backed C/C++, just-lsp, markdown-oxide+dprint, yaml-language-server, lua-language-server+stylua, nix-pinned rust-analyzer), populate `samples/`, and run the full `hx --health` sweep.
- **Components to build:** `langs/c-based.nix`, `langs/just.nix`, `langs/markdown.nix`, `langs/yaml.nix`, `langs/shell.nix` (lua portion), `langs/rust.nix` (rust-analyzer pin), and the entire `samples/` directory.
- **Dependencies:** 2B committed.
- **Exit criteria:** `hx --health <lang>` produces check marks in LSP, Formatter, Highlight, Textobject, and Indent columns for all 22 covered languages (Debug Adapter excluded). Each sample file under `samples/` opens in helix with the correct LSP attached (verified via `:lsp-workspace-stats`) and `:format` produces no error. The intentional issue in each sample surfaces as a diagnostic.
- **Risk flags:** rust-analyzer pin may shadow rustup-managed installation. If the maintainer's Rust workflow breaks, document the rustup → nix transition and consider rust-overlay as a follow-up. [ASSUMPTION] just-lsp packaging in the maintainer's nixpkgs channel is current; if the channel is too old, pin a newer nixpkgs input or skip the just entry until the channel catches up.

---

## 7. Implementation Management

### 7.1 Sequencing

The dependency graph is linear: 2A → 2B → 2C. None of these can parallelize because they all touch the same module tree. Within each phase, file order does not matter (Nix evaluation is order-independent inside an `imports` list).

### 7.2 Ownership

Single-maintainer flake; ownership is implicit. Notable cross-cutting concerns:
- **`programs.helix.settings`** lives in `settings.nix` and is owned by the editor layer. If a future track wants to change keybindings, the touch point is `default.nix`.
- **`home.packages` for language tools** is distributed across the language files. There is no central package list to coordinate.
- **Other modules adding to `home.packages`** (e.g., `cli.nix`) may overlap with packages declared here (`pkgs.just`, `pkgs.bash-language-server` if it's already pulled in elsewhere). Nix deduplicates derivations — no conflict, but the maintainer should be aware that a package can appear in multiple files' `home.packages`. The convention is: the language file owns it from helix's perspective, even if it's also declared elsewhere.

### 7.3 Critical path

The critical path is 2A. If 2A breaks the helix module (e.g., a typo in `langs/default.nix` causes the imports chain to fail evaluation), the entire helix configuration is unusable until reverted. 2B and 2C are smaller per-commit risk because each only touches a subset of files.

### 7.4 Integration points

- **`hx --health` baseline capture before 2A.** This is a one-shot integration point. Capture the current output to a file outside the flake (e.g., `~/helix-health-baseline.txt`). After each phase, re-capture and diff. This provides the regression detection that no automated test can provide for an editor configuration.
- **Backup of original `helix.nix`.** Before 2A, copy the current `home/modules/editor/helix.nix` to `home/modules/editor/helix.nix.bak`. Do not delete until 2A is committed and one full day of normal use confirms no regression.
- **Sample files vs. runtime tools.** `samples/` is verified manually per language. There is no integration test that opens each sample file programmatically. This is intentional — see §8.

### 7.5 Breaking changes

- **[BREAKING] Pyright removal.** Any Python project that depends on pyright-specific diagnostics or pyright's exact rule names will see different output from ty. Maintainer accepts this per Decision 2.
- **[BREAKING] rust-analyzer source change.** rust-analyzer goes from rustup-managed to nix-managed. Version may differ (nixpkgs's rust-analyzer is typically slightly behind rustup's nightly). If the maintainer was relying on rustup nightly's rust-analyzer features, this is a small regression; mitigated by future fenix overlay (recorded as future work).
- **[BREAKING] hyprlang scope narrowing.** Any non-hyprland `.conf` file the maintainer was implicitly getting hyprls hover on now gets nothing. This is the *desired* fix (false-positive removal) but if any workflow depended on it, that workflow needs adjustment.
- **[BREAKING] formatter swaps.** Files formatted with prettier may produce slightly different output when reformatted with biome. Files formatted with `nixpkgs-fmt` will be reformatted by alejandra on next save. The maintainer should expect a one-time noisy diff across the codebase the first time files are opened post-Track-2. Suggested mitigation: run a one-shot reformat-everything pass per ecosystem (one for nix, one for js/ts/json/css), commit as a separate "reformat" commit so the substantive Track 2 commits aren't polluted.

---

## 8. Validation & Testing Strategy

### 8.1 Verification matrix

| Layer | Test type | What it verifies | When |
|---|---|---|---|
| Module evaluation | `nix flake check` | All Nix syntax valid, imports resolve | After each commit |
| Module activation | `sudo nixos-rebuild switch --flake .#g14` | Module builds successfully, no missing packages | After each commit |
| Per-language packaging | `hx --health <lang>` | LSP, formatter, treesitter, indent all resolve to existing binaries | After 2B and after 2C |
| Per-language behavior | Open `samples/sample.<ext>` | LSP attaches, `:format` runs, diagnostic surfaces | After 2C |
| Workflow regression | Capture `hx --health` baseline before 2A; diff after each phase | No language went from green to red unintentionally | After every phase |
| Boot stability | Reboot after final commit | Module survives a fresh boot | After 2C |

### 8.2 Architecture fitness functions

These are checks that enforce the structural rules in §3 without manual review:

- **Single-purpose language files.** A file under `langs/` should only contribute to `programs.helix.languages` and `home.packages`. A grep-like check on each file confirms it does not touch `programs.helix.settings`, `home.activation`, `xdg.configFile`, or any other home-manager option. This can be an informal manual review or a future custom check.
- **Sample-file parity.** For every language declared under `langs/`, a corresponding file in `samples/` should exist. A simple shell loop over the language list checks this.
- **No cross-language imports.** No file in `langs/` should `import` another file in `langs/`. Trivial to verify by inspection or by grepping for `./` paths in each language file.
- **`home.packages` alignment.** Every package added by a language file should be referenced in that file's helix config. Manual verification; if it becomes a recurring slip, can be automated.

### 8.3 Local dev validation

The maintainer's per-change loop, in order:

1. Edit a single `langs/<file>.nix`.
2. Run `nix flake check`. If this fails, the edit is syntactically wrong; fix before proceeding.
3. Run `sudo nixos-rebuild switch --flake .#g14`. If this fails, a referenced package does not exist (typo, wrong attr name, missing channel update).
4. Run `hx --health <language>` for the affected language. Confirm the relevant columns now show check marks.
5. Run `hx samples/sample.<ext>`. Inside helix:
   - `:lsp-workspace-stats` confirms the LSP attached to the buffer.
   - `:format` runs the formatter (no error message in the status line).
   - The intentional issue in the sample shows as a red diagnostic.
6. If all four steps pass, commit. If not, the failure mode tells you which step to debug.

### 8.4 Observability

For an editor configuration, "observability" means: when something breaks, can the maintainer find out fast?

- **Helix LSP log:** `~/.cache/helix/helix.log` — set helix to log at info level (or debug when troubleshooting). After any language behaves wrong, this is the first place to look.
- **`:log-open` inside helix** — opens the same log in a buffer for live tailing.
- **`:lsp-workspace-stats`** — confirms whether an LSP is attached to the current buffer and shows its initialization status.
- **`hx --health <lang>`** — the always-available offline check. If a column is `✘` (red X), the package is missing from `home.packages` or from `$PATH`.
- **`echo $PATH | tr ':' '\n' | grep -E '(rust-analyzer|ty|ruff)'`** — sanity check that nix-managed binaries are actually on path and not shadowed by rustup/pipx/etc.

### 8.5 What this strategy does *not* cover

- **End-to-end LSP correctness.** No automated check confirms that hovering over a Python symbol returns the *right* type. Visual inspection of sample files is the substitute.
- **Performance regressions.** No measurement of LSP startup time is taken. If the maintainer perceives a slowdown, `time hx --health` is a coarse signal.
- **Diagnostic accuracy across all rules.** Each LSP has hundreds of diagnostic rules; this spec tests that diagnostics fire at all, not that every rule is calibrated. Per-project tuning lives in `pyproject.toml` / `biome.json` / `clangd-config`, not in the helix module.

---

## Appendix A — Migration trail to Phase B (dendritic)

This spec deliberately shapes the helix module so Phase B is mostly mechanical. When dendritic migration begins:

- Each `langs/<file>.nix` becomes a top-level `flake-parts` module with a `_class = "homeManager"` annotation.
- `langs/default.nix` (the aggregator) is replaced by `import-tree` glob discovery; the explicit `imports` list disappears.
- `helix/default.nix` and `helix/settings.nix` become two more top-level modules under `modules/editor/helix/`.
- `samples/` may be promoted to `templates/helix-test/` if Phase B introduces a test flake; otherwise it stays where it is.
- The web.nix and shell.nix grouping decision may be re-evaluated; with `import-tree`, the cost of per-file is lower (no aggregator to maintain), so splitting them becomes more attractive.

The core promise: no `langs/` file written today should need to be rewritten for Phase B. They get *moved* and possibly *renamed*, but their internal structure (the language entry plus language-server entries plus packages) is the same shape Phase B wants. This is the payoff of the registry pattern decided in §3.1.

---

## Appendix B — Bug-to-file map

Quick reference for which bug lives in which file post-Track-2:

| Audit bug | Fix location | Verification |
|---|---|---|
| #1 typst file-types misplaced | `langs/typst.nix` | `hx --health typst` shows tinymist; opening `samples/sample.typ` attaches it |
| #2 asm name doesn't exist in helix | `langs/asm.nix` | `hx --health gas` and `hx --health nasm` both green; old `asm` row is gone |
| #3 ruff-lsp deprecated | `langs/python.nix` | `hx --health python` shows `ty` and `ruff`, no `ruff-lsp` |
| #4 hyprlang matches all .conf | `langs/hyprlang.nix` | `:lsp-workspace-stats` on a non-hyprland `.conf` shows no LSP |
| #5 nixpkgs-fmt + nixfmt duplication | `langs/nix.nix` | `hx --health nix` shows `alejandra` as formatter |

---

**End of spec.**