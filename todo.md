# Dendritic Refactor — Implementation Plan

**Target:** `yrrrrrf`'s NixOS configuration (single-host, NixOS 25.11, Home Manager nested, ASUS G14)
**Author:** Principal architect view
**Status:** Complete — v0.0.1 architecture landed.

---

## 0. Executive Summary

This plan migrates an already-modular NixOS flake into the **dendritic pattern** — a Nixpkgs-module-system convention where every `.nix` file is a top-level `flake-parts` module, lower-level configurations (NixOS, Home Manager) are stored as option values on the top-level config, and the file system layout names features rather than classes. The migration eliminates `specialArgs` pass-through, removes manual `import { inherit pkgs; }` for package buckets, replaces hand-maintained `default.nix` import chains with recursive directory walking, and structures profiles (`dev`, `minimal`, future `gaming`/`cybersec`) as single aspect files that span both NixOS specialisations and Home Manager bundles. It also lands four orthogonal improvements that have been gaps: `nh` as the rebuild CLI, `direnv` + `nix-direnv` for per-project shells, `agenix` for declarative secrets, and `nix-index` + `comma` for ad-hoc package execution. The result is a configuration where adding a new feature, a new persona, or a new host costs one file with zero edits to existing files — a property worth far more at year 3 and beyond than the one-time cost of the refactor.

---

## 1. Context & Constraints

### Project state
- Single host: `g14` (ASUS Zephyrus, NVIDIA + integrated graphics, dGPU switching via `asusctl`).
- Single user: `yrrrrrf`.
- One Linux class only — no `nix-darwin`, no remote builders.
- NixOS 25.11 stable as base, with a curated unstable overlay for a handful of fast-moving packages (`uv`, `deno`, `bun`, `supabase-cli`, `antigravity`).
- Home Manager pinned to `release-25.11`, evaluated *inside* the NixOS system (not a standalone HM flake output).
- Existing modular tree: `host/`, `system/`, `home/modules/`, `home/profiles/`. Most leaf files are already module-shaped.
- Existing tooling: `justfile` as the human entry point; `alejandra` as the formatter.

### Goals
- Adopt the dendritic pattern in full (no hybrid).
- Add `nh` as the rebuild CLI, drive the justfile from it.
- Preserve NixOS specialisations (`dev`, `minimal`) and make the addition of future profiles (`gaming`, `cybersec`) cost one file.
- Eliminate `specialArgs` pass-through.
- Fill gaps: secrets management, project-local devshells, automatic garbage collection.

### Scale targets
- 1 host today. Architecture must absorb a second host (desktop, server) without touching existing host files.
- 1 user today. Architecture must absorb additional users by adding files to `src/users/`.
- 3 profiles today (`default`, `dev`, `minimal`). Architecture must absorb 5+ profiles linearly.

### Architectural rules
- Every `.nix` file under `src/` is a `flake-parts` module of the top-level configuration. No exceptions.
- No `specialArgs`, no `extraSpecialArgs` for sharing values. Cross-file communication happens via top-level `config` options.
- No relative imports between feature files. Files reference each other via `self.nixosModules.<x>` / `self.homeModules.<x>` or via top-level `config.flake.lib.*`.
- No `default.nix` import-chain files. `import-tree` handles all discovery.
- Generated files (`hardware-configuration.nix`) live at project root, outside `src/`, to avoid `import-tree` walking them.
- Aspect-oriented file content: one file = one feature, spanning every class that feature touches.

### Out of scope (deferred, intentionally not in this plan)
- `disko` — declarative partitioning. Revisit when a reinstall is planned.
- `stylix` — system-wide theming. Existing `theme.nix` works; merger is its own project.
- `impermanence`, `lanzaboote` — too far from current workflow to absorb in the same refactor.
- `nushell` — current zsh setup is fully dialed; not changing shells.
- GitHub Actions / any CI runner — `just check` covers local verification.
- `nh` clean settings beyond the default schedule — tune later if generations accumulate too fast.
- Multi-host wiring — architecture supports it but no second host is being added.

### Assumptions [ASSUMPTION]
- The user has commit access to the repo and rebuilds the system themselves; no team workflow.
- The age key for `agenix` will live at `/etc/ssh/ssh_host_ed25519_key` (the existing SSH host key) — standard agenix convention, no new key material to generate.
- `nh` 4.x semantics are stable (`os switch`, `clean all`, etc.); option names below match nixpkgs 25.11.
- `vic/import-tree` is the chosen walker; its filter API is sufficient (it skips non-`.nix` files by default).
- `flake-parts` major version stays compatible for the duration of NixOS 25.11.
- The user is comfortable running one or two interactive `agenix` commands to bootstrap the first encrypted file.

---

## 2. Architecture Overview

### Top-level shape

Three layers, evaluated outermost-first:

```
┌────────────────────────────────────────────────────────────────┐
│  flake.nix                                                     │
│   - Inputs (nixpkgs, nixpkgs-unstable, home-manager,           │
│     nixos-hardware, flake-parts, import-tree, agenix)          │
│   - Reads ./unstable.nix → builds unstable-overlay             │
│   - Calls flake-parts.lib.mkFlake with import-tree ./src       │
└──────────────┬─────────────────────────────────────────────────┘
               │
               ▼
┌────────────────────────────────────────────────────────────────┐
│  Top-level flake-parts configuration                           │
│   - perSystem.{packages, checks, formatter, devShells}         │
│   - flake.lib.{users, libsets, ...}      (cross-file values)   │
│   - flake.modules.nixos.<aspect>         (NixOS modules)       │
│   - flake.modules.homeManager.<aspect>   (HM modules)          │
│   - flake.nixosConfigurations.<host>     (the actual systems)  │
└──────────────┬─────────────────────────────────────────────────┘
               │  composes  ▼
┌────────────────────────────────────────────────────────────────┐
│  Lower-level configurations                                    │
│   - nixosConfigurations.g14   ◄── built from flake.modules.*   │
│     └─ home-manager nested    ◄── built from same source       │
└────────────────────────────────────────────────────────────────┘
```

### Core domain vs supporting

- **Core domain**: the *aspect catalog* under `src/` — each `.nix` file is one aspect of the system (CUDA, fonts, Hyprland, Helix, the `dev` profile, etc.). This is what evolves over the system's life.
- **Supporting**: the glue (`flake.nix`, `unstable.nix`, `justfile`, the host wrapper). These are written once and rarely touched.
- **External**: nixpkgs, home-manager, agenix, flake-parts, import-tree. Pinned via `flake.lock`.

### Information flow

- Cross-cutting values (user identity, library sets, shared paths) live as `flake.lib.*` options. Any aspect file can read and write them. This replaces `specialArgs`.
- An aspect file that touches two classes (e.g., a profile that adds a NixOS specialisation *and* a Home Manager bundle) declares both `flake.modules.nixos.<x>` and `flake.modules.homeManager.<x>` in the same file. The top-level merge engine handles composition.
- Host wiring files in `src/host/` consume `flake.modules.nixos.*` aspects by name to assemble `flake.nixosConfigurations.<host>`. The host file is the *only* place that names aspects explicitly — everywhere else, aspects are anonymous contributors to the catalog.

---

## 3. Design Patterns & Code Standards

### Pattern 1 — Dendritic (top-level module-system) [primary]

**What it solves.** A traditional NixOS flake mixes three different file shapes — flake outputs, NixOS modules, Home Manager modules — and uses relative imports plus `specialArgs` to weave them together. The result: when you open a file, you can't tell what kind of expression it contains without reading it, and refactoring a feature means hunting through several files in different shapes. The dendritic pattern collapses all three shapes into one: every file is a `flake-parts` module of the same top-level configuration.

**How it's applied here.** A `flake-parts` framework owns evaluation. `import-tree ./src` recursively imports every `.nix` file as a peer module of the top-level config. Lower-level configurations (NixOS systems, Home Manager users) are stored as option values (`flake.modules.nixos.<aspect>`, `flake.modules.homeManager.<aspect>`) of type `deferredModule` — the type's merge semantics let many files contribute to the same aspect without conflict.

**What it protects against.**
- *Year 3:* adding a fifth profile costs one file. Without dendritic, it costs edits to profile registry, possibly a `default.nix` chain, and the host wiring.
- *Year 5:* migrating to nix-darwin or adding a second host costs zero edits to existing aspect files. They're class-agnostic by construction.
- *Year 10:* the file system is a flat catalog of features rather than a hierarchy reflecting a long-dead organizational scheme. Searching for "where is X configured" is `grep`-able, not a tree walk.

### Pattern 2 — Aspect-oriented module design

**What it solves.** Cross-cutting concerns (a "profile" that bundles a NixOS specialisation + an HM module + some packages) traditionally fragment across the tree, requiring developers to chase the parts and keep them in sync.

**How it's applied here.** A single aspect file declares everything a feature needs across all relevant classes. The `dev` profile file declares `flake.modules.nixos.specialisations.dev` (the boot menu entry) and `flake.modules.homeManager.dev` (the package and program bundle) and any cross-cutting `flake.lib.*` values in the same place. To delete the feature: delete the file. To rename it: rename the keys inside, file path is irrelevant.

**Standard:** when a file's content would touch multiple aspects, split it into multiple files (one aspect per file), not multiple sections of one file.

### Pattern 3 — Options as the shared-state bus

**What it solves.** Files need to share values: the username, library lists for `LD_LIBRARY_PATH`, paths to scripts, etc. The non-dendritic answer is `specialArgs`; the dendritic answer is declaring an option on the top-level config and reading from it.

**How it's applied here.** A small `flake.lib` namespace holds shared values: `flake.lib.users.<name>` for user records, `flake.lib.libsets.{gui,build}` for grouped package lists consumed by env-var builders, `flake.lib.scripts.<name>` for paths to shell script files referenced from multiple aspects. Each shared value is declared as an option in exactly one file (the file that owns the concept), and read by any file that needs it.

**What it protects against.** Type checking and option merge semantics mean a stale reference fails evaluation immediately rather than silently producing a broken system. Compare with `specialArgs` where a typo in an argument name surfaces as a runtime error inside a HM module 30 seconds into a rebuild.

### Pattern 4 — Profile-as-aspect-bundle

**What it solves.** Profiles aren't a configuration class of their own; they're a *bundle* of contributions across classes. The original config expressed them as HM-only profiles wired by NixOS specialisations from a different file — the bundle was implicit.

**How it's applied here.** Each profile is one file in `src/profiles/`. The file declares the NixOS specialisation entry (which selects the right HM aspect at boot) and the HM aspect itself (which composes its package and program contributions). The `default` profile is the universal base — it has no specialisation entry (it *is* the default), only the HM aspect. Specialised profiles (`dev`, `minimal`, future `gaming`) extend or replace pieces of the base.

**Standard:** a profile file may import other aspects via `imports`, but may not *define* aspects that aren't profile-specific. Anything reusable lives outside `src/profiles/` and is referenced.

### Naming conventions

- File names match the aspect name they own (`nh.nix` declares `flake.modules.nixos.nh`).
- Aspect names are lowercase, hyphen-separated, scoped by purpose (`nh`, `agenix`, `direnv`, `nix-index`).
- Profile names match the specialisation name (`dev.nix` → `specialisation.dev`).
- User files are named by the user's login (`yrrrrrf.nix` → `flake.lib.users.yrrrrrf`).
- Host directories are named by the host name (`src/host/g14/`).

### Dependency direction rules

- **Aspects** may read `flake.lib.*` and may declare contributions to `flake.modules.*`. They MUST NOT reference other aspect files via relative paths.
- **Profiles** may import aspects via `imports = [ self.homeModules.<x> ]` and may declare specialisations. They MUST NOT define non-profile aspects.
- **Host files** may import aspects via `imports = [ self.nixosModules.<x> ]` and assemble `flake.nixosConfigurations.<host>`. They MUST NOT declare aspects of their own beyond hardware-specific ones (e.g., `hardware-configuration.nix` reference).
- **`flake.nix`** is glue only. It declares inputs, applies the unstable overlay, and invokes `mkFlake` with `import-tree ./src`. No business logic.

### Error handling and observability

- Build-time errors: rely on Nix's evaluation errors. Type mismatches on options surface at `nix flake check`.
- Runtime errors during rebuild: surface via `nh` (which wraps `nixos-rebuild` with `nvd` diffs and clearer output).
- System health: existing tools (`asusctl`, `bottom`, `nvtop` if installed) remain the runtime observability surface. No additions in this refactor.

---

## 4. Component Map & Directory Structure

### Directory tree

```
nixos/
├── flake.nix                       # flake-parts entry, ~30 lines
├── unstable.nix                    # attrset of packages to pull from unstable
├── hardware-configuration.nix      # generated by nixos-generate-config
├── justfile                        # rewritten: nh-backed + new recipes
├── .gitignore
├── README.md                       # documents the dendritic shape and conventions
└── src/                            # walked recursively by import-tree
    ├── users/
    │   └── yrrrrrf.nix             # declares flake.lib.users.yrrrrrf
    ├── host/
    │   └── g14/
    │       ├── g14.nix             # declares flake.nixosConfigurations.g14
    │       └── networking.nix      # NetworkManager, firewall, hostname
    ├── system/
    │   ├── core.nix                # bootloader, locale, time zone
    │   ├── fonts.nix
    │   ├── services.nix
    │   ├── podman.nix
    │   ├── nvidia.nix
    │   ├── cuda.nix
    │   ├── nh.nix                  # NEW — programs.nh + clean systemd timer
    │   └── agenix.nix              # NEW — age.secrets wiring, key path
    ├── home/
    │   ├── desktop/                # hyprland.nix, waybar.nix, dunst.nix,
    │   │                           #   rofi.nix, theme.nix, swayosd.nix,
    │   │                           #   wezterm.nix, hypridle.nix, hyprlock.nix
    │   │                           # (+ static .conf, .css siblings)
    │   ├── editor/
    │   │   └── helix.nix
    │   ├── shell/
    │   │   ├── zsh.nix             # zsh + aliases + companion enables
    │   │   ├── fastfetch.nix
    │   │   ├── yazi.nix
    │   │   ├── direnv.nix          # NEW
    │   │   ├── nix-index.nix       # NEW (+ comma)
    │   │   └── difftastic.nix      # NEW
    │   ├── packages/
    │   │   ├── cli.nix             # categorised CLI tool lists
    │   │   ├── desktop.nix         # GUI apps
    │   │   ├── libs.nix            # declares flake.lib.libsets.{gui,build}
    │   │   └── dev/
    │   │       ├── core.nix        # renamed from packages.nix (build, ides)
    │   │       └── lang/           # rust/python/go/... migrated as-is
    │   └── scripts.nix             # HM module: shell scripts + ~/.local/bin
    │                               #   .sh files stay where they currently live
    └── profiles/
        ├── default.nix             # base HM aspect (no specialisation entry)
        ├── dev.nix                 # specialisation + HM aspect
        └── minimal.nix             # specialisation + HM aspect
```

### Component map

#### `flake.nix`
- **Responsibility:** Pin inputs, read `unstable.nix`, build the unstable overlay, invoke `flake-parts.lib.mkFlake` with `import-tree ./src` as the only top-level import.
- **Interfaces exposed:** flake outputs (`nixosConfigurations`, `packages`, `checks`, `formatter`, `devShells`) — all populated by the `src/` walk, none defined here.
- **Dependencies consumed:** `nixpkgs`, `nixpkgs-unstable`, `home-manager`, `nixos-hardware`, `flake-parts`, `import-tree`, `agenix`.
- **Must NOT:** contain feature logic, contain module definitions, contain anything that needs to be edited when adding a new aspect.

#### `unstable.nix`
- **Responsibility:** Declare which packages come from `nixpkgs-unstable` and (optionally) how they're overridden. Single source of truth for the unstable surface.
- **Interfaces exposed:** A plain attribute set. Each key is a package name; each value is either `null` (take from unstable as-is) or a function `(unstablePkg → overrideAttrsArg)` to customize. Read by `flake.nix` to construct the overlay.
- **Dependencies consumed:** None (pure data).
- **Must NOT:** import nixpkgs, evaluate packages, contain side effects. Adding a package = adding a key with `null`.

#### `hardware-configuration.nix`
- **Responsibility:** Hardware-specific kernel modules, filesystem entries, hardware-detected NixOS module fragment.
- **Location at root:** prevents `import-tree` from walking into it (it would fail because the file is a standard NixOS module, not a `flake-parts` module).
- **Interfaces exposed:** a standard NixOS module value.
- **Must NOT:** be hand-edited. Regenerated via `nixos-generate-config --show-hardware-config > hardware-configuration.nix` if hardware changes.

#### `src/users/<name>.nix`
- **Responsibility:** Declare user identity records on `flake.lib.users.<name>` — username, home directory, full name, email, any per-user data referenced by multiple aspects.
- **Interfaces exposed:** options under `flake.lib.users.<name>`.
- **Dependencies consumed:** none.
- **Must NOT:** configure programs, install packages, declare HM modules. Pure data.

#### `src/host/<host>/<host>.nix`
- **Responsibility:** Assemble a NixOS system for one host. Imports the right aspects (`flake.modules.nixos.<x>`), declares the `users.users.<name>` entry, wires `home-manager` to the right profile, declares specialisations.
- **Interfaces exposed:** an entry in `flake.nixosConfigurations.<host>`.
- **Dependencies consumed:** all relevant aspects from `flake.modules.nixos.*`, the user record from `flake.lib.users.*`, hardware-specific imports.
- **Must NOT:** define general-purpose aspects (those go under `src/system/` or `src/home/`).

#### `src/host/<host>/networking.nix`
- **Responsibility:** Host-specific network configuration — hostname, NetworkManager, firewall rules.
- **Interfaces exposed:** `flake.modules.nixos.<host>-networking` (host-scoped, not a shared aspect).
- **Dependencies consumed:** none.

#### `src/system/*.nix`
- **Responsibility:** General-purpose NixOS aspects available to any host. Each file owns one aspect (`core`, `fonts`, `cuda`, `nh`, etc.).
- **Interfaces exposed:** `flake.modules.nixos.<aspect>`.
- **Dependencies consumed:** other aspects (rarely; via the top-level config), `flake.lib.*` values.
- **Must NOT:** declare host-specific anything, reach into HM (use `src/home/` for that).

#### `src/home/*/*.nix`
- **Responsibility:** Home Manager aspects — per-program configuration plus its package dependencies. Each file owns one program or category.
- **Interfaces exposed:** `flake.modules.homeManager.<aspect>`.
- **Dependencies consumed:** `flake.lib.libsets.*` for build/runtime library groups, other HM aspects via the top-level config.
- **Must NOT:** declare NixOS-level options, hard-code paths that belong in `flake.lib`.

#### `src/home/packages/libs.nix`
- **Responsibility:** Declare grouped library lists (`gui`, `build`) as `flake.lib.libsets.*` options. Consumed by env-var builders (`LD_LIBRARY_PATH`, `PKG_CONFIG_PATH`) in profile files.
- **Interfaces exposed:** `flake.lib.libsets.{gui,build}` (list options), plus an HM aspect contribution that adds the same lists to `home.packages` for the relevant profiles.
- **Dependencies consumed:** `pkgs`.
- **Must NOT:** install packages directly into every profile — let the profile that needs them import the aspect.

#### `src/home/packages/{cli,desktop}.nix`
- **Responsibility:** Categorised package lists (CLI tools by purpose: nav/view/text/git/system/net/archive/bench/shell/rust-dev/misc; GUI apps by purpose).
- **Interfaces exposed:** `flake.lib.pkgsets.cli.*` / `flake.lib.pkgsets.desktop.*` plus HM aspect contributions that merge the categories into `home.packages` for the right profiles.
- **Must NOT:** decide which profile gets which category — that's the profile's job.

#### `src/home/packages/dev/lang/*.nix`
- **Responsibility:** Per-language Home Manager aspects. Each file configures `programs.helix.languages.*` for one language and adds the language toolchain to `home.packages`.
- **Interfaces exposed:** `flake.modules.homeManager.dev-lang-<language>`.
- **Migration note:** these are already module-shaped in the current config. Migration is moving them into `src/home/packages/dev/lang/` and wrapping the existing module value in `{ flake.modules.homeManager.dev-lang-<x> = <existing module>; }`.

#### `src/home/scripts.nix`
- **Responsibility:** Symlink the existing shell scripts (which stay where they currently live) into `~/.local/bin`.
- **Interfaces exposed:** `flake.modules.homeManager.scripts`.
- **Notes:** the `.sh` files themselves are not migrated. They remain in their current location and are referenced via path. `scripts.nix` is the only file that knows about that path.

#### `src/profiles/<name>.nix`
- **Responsibility:** Declare one profile. For specialised profiles, declare both `flake.modules.nixos.specialisations.<name>` (the specialisation entry, which selects the right HM aspect at boot) and `flake.modules.homeManager.<name>` (the HM bundle). For `default`, declare only the HM bundle.
- **Interfaces exposed:** as above.
- **Dependencies consumed:** HM aspects via the top-level config (composed into the profile's HM bundle), `flake.lib.libsets.*`, `flake.lib.pkgsets.*`.

---

## 5. Trade-off Analysis

### DECISION: Migration strategy

```
DECISION: How aggressive a dendritic adoption?
OPTIONS CONSIDERED:
  A. Full dendritic — flake-parts + import-tree, every .nix is a top-level module.
     pros: maximum future flexibility; idiomatic; aligns with the canonical pattern.
     cons: framework dependency; one-time refactor cost.
  B. Hybrid — keep current shape, fix package-bucket pattern, kill specialArgs only.
     pros: lower migration cost; no new framework.
     cons: leaves a non-uniform tree; doesn't pay off when a second host arrives.
  C. Stay put — no refactor, just add nh and other small wins.
     pros: zero migration cost.
     cons: every problem we've named (specialArgs, package buckets, manual import chains) stays.
CHOSEN: A.
REASON: The user explicitly authorized full adoption. Cost is paid once; benefits compound. The canonical pattern has community support, documentation, and a clear migration path forward (e.g., adopting dendrix layers later).
REVISIT IF: flake-parts is abandoned by its maintainers, or a strictly better top-level pattern emerges in the Nix community.
```

### DECISION: Where the unstable overlay lives

```
DECISION: How to express the unstable-package surface.
OPTIONS CONSIDERED:
  A. Inline in flake.nix — current state; the overlay function lives in the `let` block.
     pros: zero indirection.
     cons: editing the unstable list means editing flake.nix; mixes glue with content.
  B. unstable.nix at root, plain attrset of names → null-or-override-fn.
     pros: tiny edit surface; one place to look; pure data; override escape hatch preserved.
     cons: one extra file.
  C. unstable.nix as a flake-parts module inside src/ that contributes an overlay aspect.
     pros: stylistically purer (every file a module).
     cons: hides the unstable surface inside the walking tree; editing it requires diving into src/.
CHOSEN: B.
REASON: The user's workflow centers on "what am I pulling from unstable today?" That question deserves a glance at one file at the root, not a tree walk. The override escape hatch (for the commented-out cisco case and any future similar) is preserved as the value type. flake.nix reads it as data and constructs the overlay programmatically.
REVISIT IF: the unstable list grows past ~30 entries with many overrides, at which point a more structured shape might help.
```

### DECISION: Secrets manager

```
DECISION: agenix vs sops-nix.
OPTIONS CONSIDERED:
  A. sops-nix — supports age + GPG, YAML/JSON files, broader surface.
     pros: flexible; mature; supports multiple identity types.
     cons: larger config; YAML structuring; more concepts to learn.
  B. agenix — age-only; encrypted blobs; one tool, one key.
     pros: minimal; uses existing SSH host key as the identity; trivial to bootstrap.
     cons: less flexible if the workflow later needs hierarchical secret access.
CHOSEN: B.
REASON: No existing GPG workflow. Single-user. The "use the SSH host key as the age identity" convention means there's no new key material to manage. Adding the first secret is one `agenix -e foo.age` command.
REVISIT IF: secrets need to be readable by multiple identities (multi-user, multi-host with different keys), or the team grows.
```

### DECISION: Garbage collection strategy

```
DECISION: nh.clean only, nix.gc.automatic only, or both.
OPTIONS CONSIDERED:
  A. nh.clean on a systemd timer only.
     pros: single tool owns GC; nvd-style diffs during operation; consistent with the "nh is the rebuild CLI" choice.
     cons: depends on nh remaining maintained.
  B. nix.gc.automatic + nix.optimise.automatic, no nh timer.
     pros: native NixOS, no third-party dependency for GC.
     cons: less informative output; inconsistent with the rest of the rebuild workflow.
  C. Both.
     pros: belt and suspenders.
     cons: redundant; two timers doing overlapping work.
CHOSEN: A.
REASON: Consistency with the broader "nh owns the rebuild surface" decision. The `just clean` recipe calls `nh clean all`; the systemd timer does the same on a weekly schedule.
REVISIT IF: nh becomes unmaintained or its CLI shape breaks across a major version.
```

### DECISION: Specialisations vs profile-swap-at-rebuild

```
DECISION: How to express the persona switch.
OPTIONS CONSIDERED:
  A. NixOS specialisations — boot menu entries; runtime switch via switch-to-configuration.
     pros: ergonomic boot-time selection; runtime switch is free; survives the rebuild cycle.
     cons: every specialisation builds at every rebuild (small cost on small profiles).
  B. Swap the active profile by passing a flag to nh and rebuilding.
     pros: only the active profile is built.
     cons: switching costs a rebuild; no boot-time selection.
CHOSEN: A.
REASON: The boot-time selection is a real UX feature. Cost of building the unused specialisation is small for `minimal` and `dev` and bounded for future additions. Runtime switch falls out for free.
REVISIT IF: rebuild time becomes painful, or a profile is so large that the build cost outweighs the UX.
```

### DECISION: Profile file layout

```
DECISION: One file per profile that spans classes, or split by class.
OPTIONS CONSIDERED:
  A. One file per profile — declares both the NixOS specialisation entry and the HM aspect.
     pros: feature locality; deleting a profile is `rm src/profiles/<name>.nix`.
     cons: file mixes two classes (mitigated by clear sections).
  B. Split — src/system/specialisations/<name>.nix + src/home/profiles/<name>.nix.
     pros: each file is single-class.
     cons: every profile costs two files in two trees; deletion is a coordinated edit.
CHOSEN: A.
REASON: The dendritic spirit is one-file-per-feature, where "feature" can absolutely span classes — that's the entire point of aspect-oriented design. Renaming "personas" to "profiles" preserves continuity with the prior config and matches NixOS's own boot-menu vocabulary.
REVISIT IF: a single profile file grows past ~100 lines, at which point splitting into <name>/{specialisation.nix, home.nix} is a reasonable reorganization inside the profiles tree.
```

### DECISION: Library set sharing mechanism

```
DECISION: How to expose libs.gui / libs.build for env-var consumption.
OPTIONS CONSIDERED:
  A. Top-level options on flake.lib.libsets.{gui,build}.
     pros: typed; readable from any file; idiomatic dendritic.
     cons: requires declaring the options.
  B. Re-export from a self.* output (e.g., self.libsets).
     pros: works without option declaration.
     cons: outside the option-merge system; no type checking.
  C. Keep the current manual import pattern.
     pros: minimal change.
     cons: defeats the migration's purpose.
CHOSEN: A.
REASON: The option system is the right tool for typed, merge-aware shared values. Cost of declaring the option is one extra block per shared value; payoff is everywhere they're consumed.
REVISIT IF: option declaration boilerplate becomes a significant maintenance burden (unlikely at current scale).
```

### DECISION: Shell scripts location

```
DECISION: Where the .sh files live.
OPTIONS CONSIDERED:
  A. Leave them in their current location, reference via path from src/home/scripts.nix.
     pros: zero churn on the scripts themselves; preserves their git history; .sh files invisible to import-tree.
     cons: scripts.nix has one relative path to maintain.
  B. Move them under src/home/scripts/ (a sibling directory of scripts.nix).
     pros: visual grouping.
     cons: churn for no architectural benefit; .sh files in src/ blurs the "src is Nix code" rule.
CHOSEN: A.
REASON: User explicitly requested this. The scripts.nix path reference is one line; the migration cost is zero.
REVISIT IF: scripts need to live in nix-store paths for hardening reasons (use pkgs.writeShellScriptBin instead).
```

### DECISION: CI surface

```
DECISION: Whether to land a CI runner workflow.
OPTIONS CONSIDERED:
  A. GitHub Actions workflow that runs nix flake check on push.
     pros: catches regressions before they hit the host.
     cons: external dependency; runner setup; the user has rejected this.
  B. just check recipe that runs nix flake check + alejandra --check locally.
     pros: local verification is fast; no external infra; user keeps full control.
     cons: nothing catches a broken commit if the user forgets to run it before pushing.
CHOSEN: B.
REASON: User explicit preference. Local verification is sufficient for a single-developer, single-host config. If a regression slips through, the next rebuild catches it and rollback is one generation.
REVISIT IF: a second developer joins, or the repo becomes a template others depend on.
```

### DECISION: Import-tree library vs hand-rolled walker

```
DECISION: How files in src/ get discovered.
OPTIONS CONSIDERED:
  A. vic/import-tree — purpose-built walker for this pattern.
     pros: handles edge cases (default.nix exclusion, non-.nix files); community-tested.
     cons: one more flake input.
  B. Hand-rolled via builtins.readDir + lib.filesystem.listFilesRecursive.
     pros: zero new inputs.
     cons: edge cases are on us; one more thing to maintain.
CHOSEN: A.
REASON: The 5-minute cost of pinning a 50-line library is much less than maintaining a walker. import-tree has handled the cases we'd otherwise discover one bug at a time.
REVISIT IF: import-tree is abandoned or its semantics change in a breaking way.
```

---

## 6. Phased Implementation Plan

Phases are sequential. Each is independently shippable: at the end of each phase the system rebuilds and works. Bisection across phase boundaries is trivial; bisection within a phase is per-commit.

### Phase 0 — `nh` lands on the existing config [PRE-REFACTOR]
- **Goal:** ergonomic rebuild CLI before touching anything structural.
- **Components built:** one new system module declaring `programs.nh.enable`, `programs.nh.flake`, `programs.nh.clean.enable`, clean schedule. Justfile recipes rewritten: `just build` → `nh os build`, `just switch` → `nh os switch`, `just update` → `nh os switch --update`, `just clean` → `nh clean all`. Old `gc` and `generations` recipes removed.
- **Dependencies:** existing flake (no new inputs).
- **Exit criteria:** `just switch` rebuilds the running config via `nh`, `nh os build` produces a buildable closure, the systemd clean timer is active (`systemctl list-timers | grep nh`).
- **Risk flags:** none meaningful. `nh` is mature and the option surface is small.

### Phase 1 — Dendritic scaffolding [FOUNDATION]
- **Goal:** every piece of the framework in place, an empty but valid `src/` tree, the system still builds via a temporary import bridge.
- **Components built:**
  - New flake inputs: `flake-parts`, `import-tree`, `agenix`.
  - `unstable.nix` at root: extract the current overlay list into the new attrset shape; `flake.nix` reads it.
  - Minimal `flake.nix`: imports `flake-parts`, `home-manager.flakeModules.home-manager`, calls `mkFlake` with `import-tree ./src` plus a temporary bridge module that re-exports the existing `host/g14/configuration.nix` as `flake.nixosConfigurations.g14`.
  - Empty `src/` tree with placeholders (one file per planned directory) so `import-tree` walks something.
  - `just check` recipe that runs `nix flake check && alejandra --check .`.
- **Dependencies:** Phase 0 complete (so `nh` exists to rebuild).
- **Exit criteria:** `just check` passes. `just switch` rebuilds successfully. The flake is dendritic *in shape* even though all real content still lives in the old tree.
- **Risk flags:** `flake-parts` + `home-manager` integration requires importing the right flake module (`home-manager.flakeModules.home-manager`) — easy to forget. The bridge module that re-exports the old config is throw-away; do not let it harden.

### Phase 2 — Migrate `lib` and `system` aspects
- **Goal:** the cross-cutting values and system-level modules live in `src/`.
- **Components built:**
  - `src/users/yrrrrrf.nix` declares `flake.lib.users.yrrrrrf` from the current `home/users/yrrrrrf.nix`. Old file deleted.
  - `src/system/*.nix` migrated one at a time: `core.nix`, `fonts.nix`, `services.nix`, `podman.nix`, `nvidia.nix`, `cuda.nix`. Each becomes a flake-parts module wrapping the existing NixOS module value under `flake.modules.nixos.<aspect>`. The bridge module is updated to import from `self.nixosModules.*` instead of relative paths.
- **Dependencies:** Phase 1.
- **Exit criteria:** the system rebuilds with all `system/` aspects served from `src/`. Old `system/` directory still present but no longer referenced.
- **Risk flags:** `cuda.nix` includes a cachix substituter — verify it's still picked up after the wrapping.

### Phase 3 — Migrate host wiring
- **Goal:** `flake.nixosConfigurations.g14` is built from `src/host/g14/`, bridge module deleted.
- **Components built:**
  - `src/host/g14/g14.nix` declares `flake.nixosConfigurations.g14` directly, importing aspects via `self.nixosModules.*`. References `../../../hardware-configuration.nix` (moved from `host/g14/hardware-configuration.nix` to repo root).
  - `src/host/g14/networking.nix` migrated.
  - `home-manager.users.<user>` wiring inside the host file references the `default` HM aspect via `self.homeModules.default` (which doesn't exist yet — this is the test that the next phase needs to deliver something).
- **Dependencies:** Phase 2.
- **Exit criteria:** rebuild succeeds with the host file living in `src/host/`. Old `host/g14/` directory deleted. Bridge module deleted.
- **Risk flags:** the `nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia` import currently sits in `configuration.nix` — preserve it in `src/host/g14/g14.nix`. **[BREAKING CHANGE]** moving `hardware-configuration.nix` is a path change; if there's any external tooling reading from the old location, update it.

### Phase 4 — Migrate `home` aspects (desktop, editor, shell)
- **Goal:** all Home Manager aspects live in `src/home/`.
- **Components built:**
  - `src/home/desktop/*.nix` — Hyprland, Waybar, Dunst, Rofi, theme, SwayOSD, WezTerm, Hypridle, Hyprlock. Each file wraps the existing HM module under `flake.modules.homeManager.<aspect>`. The `.conf` and `.css` siblings move alongside.
  - `src/home/editor/helix.nix`.
  - `src/home/shell/*.nix` — `zsh.nix` (with aliases and companion-tool enables intact), `fastfetch.nix`, `yazi.nix`. No splitting of atuin/zoxide/starship.
  - `src/home/scripts.nix` — HM module that creates `~/.local/bin` symlinks; references the existing `.sh` files at their current path.
- **Dependencies:** Phase 3.
- **Exit criteria:** every HM aspect available as `self.homeModules.<aspect>`. The current `default` profile (still bridging) imports them by name.
- **Risk flags:** the `programs.zsh.initContent` references the `fn.sh` script via a relative path inside the original `home/modules/shell/zsh.nix`. After migration, the path resolution changes — verify the `fn.sh` reference still resolves.

### Phase 5 — Migrate package aspects
- **Goal:** package buckets (the current non-dendritic part) become real aspects.
- **Components built:**
  - `src/home/packages/libs.nix` declares `flake.lib.libsets.gui` and `flake.lib.libsets.build` as list options. The HM aspect contribution merges them into `home.packages` only for profiles that opt in.
  - `src/home/packages/cli.nix` declares `flake.lib.pkgsets.cli.{nav,view,text,git,system,net,archive,bench,shell,rust-dev,misc}` and contributes per-category bundles to the HM aspect.
  - `src/home/packages/desktop.nix` mirrors the structure for GUI apps (`apps`, `creative`, `office`, `tools`).
  - `src/home/packages/dev/core.nix` (renamed from `packages.nix`) declares the `build` and `ides` lists.
  - `src/home/packages/dev/lang/*.nix` migrated one file at a time. Each wraps its existing module value under `flake.modules.homeManager.dev-lang-<language>`.
- **Dependencies:** Phase 4.
- **Exit criteria:** the `dev` profile's `LD_LIBRARY_PATH` and `PKG_CONFIG_PATH` resolve via `flake.lib.libsets.build` reads. No file in `src/` does `import ./foo.nix { inherit pkgs; }`.
- **Risk flags:** the env-var builders (`lib.makeLibraryPath`, `lib.makeSearchPath`) must see the same list of derivations they currently see — verify with `nh os build` and inspect the generated environment before switching.

### Phase 6 — Migrate profiles + specialisations
- **Goal:** `dev`, `minimal`, `default` profiles live in `src/profiles/` as aspect files. Specialisations wired from inside each profile.
- **Components built:**
  - `src/profiles/default.nix` — base HM aspect; no specialisation entry. Composes desktop, editor, shell, scripts aspects.
  - `src/profiles/dev.nix` — declares `flake.modules.nixos.specialisations.dev` and `flake.modules.homeManager.dev`. The specialisation entry sets `home-manager.users.<user>` to `self.homeModules.dev`. The HM aspect imports `self.homeModules.default` + adds dev-specific packages and env vars.
  - `src/profiles/minimal.nix` — symmetric to `dev`, but with the minimal package set.
  - Old `home/profiles/` deleted.
- **Dependencies:** Phase 5.
- **Exit criteria:** boot menu shows `dev` and `minimal` specialisations. `sudo /run/current-system/specialisation/dev/bin/switch-to-configuration switch` works at runtime. `just profile <name>` recipe added.
- **Risk flags:** specialisations build at every rebuild — verify build time hasn't ballooned. If a profile import accidentally creates a circular reference (profile → aspect → flake.lib → profile), the evaluation fails late and the error message is opaque.

### Phase 7 — New aspects [GAP-FILLING]
- **Goal:** land direnv, nix-index + comma, difftastic, agenix, and the `nh.clean` timer.
- **Components built:**
  - `src/home/shell/direnv.nix` — `programs.direnv.enable`, `programs.direnv.nix-direnv.enable`, a `direnvrc` template enabling `use_flake` with hash-based cache.
  - `src/home/shell/nix-index.nix` — `programs.nix-index.enable`, `programs.command-not-found.enable = false`, the `comma` package added to `home.packages`. Optionally, the nix-index database build can run on a weekly timer.
  - `src/home/shell/difftastic.nix` — adds `difftastic` to packages, configures git's `external-diff` via `programs.git.extraConfig`.
  - `src/system/agenix.nix` — imports `inputs.agenix.nixosModules.default`, declares an empty `age.secrets` set and the SSH host key path as the identity. Documents in a top-of-file comment how to add a new secret.
  - `src/system/nh.nix` updated (from Phase 0) to enable the clean timer with a sensible schedule (`dates = "weekly"`, `extraArgs = "--keep 5 --keep-since 7d"`).
- **Dependencies:** Phase 6.
- **Exit criteria:** `cd` into any flake'd project triggers direnv; `, hello` works; `git diff` uses difftastic; `agenix --version` works; `systemctl list-timers` shows the nh clean timer.
- **Risk flags:** direnv hash-caching needs `direnv allow` per project the first time — document in the README.

### Phase 8 — Cleanup & documentation
- **Goal:** legacy directories deleted, README written, conventions documented.
- **Components built:**
  - Delete legacy `home/`, `system/`, `host/` directories (everything should already be empty by this point).
  - Write `README.md` at repo root: the dendritic pattern in one paragraph, the directory map, "how to add a new aspect", "how to add a new profile", "how to add a new host", "how to add a secret", "how to add a package to unstable".
  - Final `alejandra .` pass.
  - Final `nix flake check`.
- **Dependencies:** Phase 7.
- **Exit criteria:** `tree` of the repo matches the spec in section 4 exactly. `nix flake check` passes. README is complete enough that someone unfamiliar with the repo can add a feature.
- **Risk flags:** none.

---

## 7. Implementation Management

### Sequencing rationale

The phases form a strict dependency chain. The reason for the order:

- **Phase 0 first** because `nh` is the tool the migration will *use*. Landing it before the refactor means every subsequent rebuild during the refactor benefits from `nvd` diffs and clearer output. Independent commit, independent value.
- **Phase 1 (scaffolding) before any migration** because the framework must exist before content can be moved into it. The temporary bridge module is the explicit safety net: the system keeps building even though `src/` is empty.
- **`lib` and `system` before `host`** because the host wiring imports system aspects. Migrating system first means the host migration can drop the bridge cleanly.
- **`host` before `home`** because the host file wires HM. Wiring it correctly requires that the HM aspects already exist (or that the wiring temporarily points at the old paths). Doing host first establishes the wiring contract; HM aspects then fill it.
- **`home` before `profiles`** because profiles compose HM aspects. Profiles last in the structural migration.
- **`packages` before `profiles`** because the package buckets are the most-edited part of the system; migrating them under the new pattern proves the option-based sharing mechanism works before profiles depend on it.
- **New aspects after structural migration** because adding a new aspect under the new pattern is the first real exercise of the pattern. Doing it during the migration mixes "is this failing because of the new aspect or because of the migration?" — separate concerns.
- **Cleanup last** because deleting the legacy tree before the migration is fully verified leaves no fallback.

### Critical path

The longest dependent chain: Phase 0 → 1 → 2 → 3 → 4 → 5 → 6. Any delay in these cascades. Phase 7 is parallelizable internally (the new aspects don't depend on each other). Phase 8 is single-step.

### Integration points

- **Phase 1 ↔ Phase 3:** the bridge module exists from Phase 1 to Phase 3. Each phase between updates the bridge to point at progressively more `src/` content. The bridge file is the synchronization point — every commit during these phases either updates the bridge or migrates a file the bridge references.
- **Phase 5 ↔ Phase 6:** profiles consume `flake.lib.libsets.*` and `flake.lib.pkgsets.*`. Phase 5 declares them; Phase 6 reads them. Phase 5 must declare a stable option name; renaming after Phase 6 means edits to multiple profile files.
- **Phase 6 ↔ Phase 7:** new aspects (direnv, agenix, etc.) integrate with profiles. The `default` profile picks up direnv; the system-level aspects (`agenix`, `nh.clean` timer) are included by the host. Decide before Phase 7 whether direnv is universal or dev-only (recommend universal: it's harmless on minimal).

### Breaking changes flagged

- **[BREAKING]** Moving `hardware-configuration.nix` from `host/g14/hardware-configuration.nix` to project root. Any external script or documentation referencing the old path needs updating.
- **[BREAKING]** Eliminating `specialArgs`. Any external module (one not in this repo) that relied on `inputs` or `username` being injected via `specialArgs` needs rewriting.
- **[BREAKING]** Renaming `home/modules/packages/dev/packages.nix` to `src/home/packages/dev/core.nix`. Internal-only; the only references are within the migrated tree.
- **[BREAKING, REVISIT IF NEEDED]** `flake-parts` and `import-tree` are now hard dependencies. Removing the pattern later means rewriting `flake.nix` and reorganizing the tree.

### Ownership

Single-developer config. The user is the sole owner of every component. No team coordination required.

### Rollback strategy

Each phase is one or more commits. NixOS generations are the ultimate rollback: `nh os switch --rollback` (or boot the previous generation) reverts to the prior working system. Git rollback to any phase boundary commit reverts the configuration. The `hardware-configuration.nix` move (Phase 3) is the only change that touches a non-source-controlled file location — keep a copy at the old path until Phase 8 if paranoid.

---

## 8. Validation & Testing Strategy

### Test types by layer

| Layer | Verification | What it verifies |
|---|---|---|
| Nix evaluation | `nix flake check` | Type-checks every option, evaluates `nixosConfigurations.g14` to a closure, fails on undeclared options. |
| Formatting | `alejandra --check .` | Every `.nix` file is canonically formatted. |
| Build correctness | `nh os build` | The full system closure builds. Generates without activating. |
| Activation correctness | `nh os switch` | The generated system activates on the running host. |
| Runtime correctness | manual smoke after switch | The smoke tests below. |
| Generational safety | NixOS generations | Roll back to any prior generation; bootloader entry persists. |

### Architecture fitness functions

These are automated checks that enforce the architecture's rules. They run inside `nix flake check`.

- **No `specialArgs` in `nixosSystem` calls** — a grep-based check in `just check` that fails if `specialArgs` appears in `src/`.
- **No relative imports between aspect files** — grep for `import \.\./` or `import \./[a-z]*\.nix` in `src/` (excluding `host/g14/g14.nix` which imports `hardware-configuration.nix`). Should produce zero matches in aspect files.
- **No top-level `with pkgs;` at file root** — minor style enforcement; `with pkgs;` is acceptable inside attribute set values but discouraged at module root.
- **Every aspect declares under `flake.modules.<class>.*` or `flake.lib.*`** — a meta-check enforced by reading the option tree after evaluation.

These fitness functions don't need to be sophisticated. A `just check` recipe that runs a few `grep` invocations alongside `nix flake check` is enough.

### Local dev validation

Before any commit, the developer runs `just check`. Before any push, `nh os build` to confirm the system closure still builds. After Phase 6, `nh os switch` and then a smoke test:

- Open a terminal: zsh + starship + aliases work.
- Open WezTerm: configuration applied.
- Launch Hyprland (or verify on next login): waybar appears, keybinds work, dunst notifications fire.
- `, hello` (after Phase 7) finds and runs hello.
- `cd` into a flake'd directory: direnv prompts.
- `git diff` shows difftastic output.
- Boot to a specialisation entry: confirm the right profile activates.
- `sudo /run/current-system/specialisation/minimal/bin/switch-to-configuration switch`: confirms runtime profile switch.

### Observability

The system is single-host single-user; production observability is over-engineering. The existing tools cover the bases:

- `bottom`, `procs`, `dust` for runtime resource use.
- `journalctl` for service logs (already there).
- `nh` outputs build/switch diffs via `nvd`.
- `systemctl list-timers` confirms the GC timer is alive.
- `nixos-rebuild list-generations` (or the equivalent `nh` command if added) shows the generational history.

No metrics pipeline, no logging service, no traces. If a service misbehaves, `journalctl -u <unit>` is the answer.

---

## 9. Risks & Watch-outs

### High-attention items

- **flake-parts + home-manager wiring [HIGH RISK at Phase 1]** — the integration requires importing `inputs.home-manager.flakeModules.home-manager` at the top level so that `flake.modules.homeManager.*` becomes a valid option. Missing this import surfaces as confusing "option X does not exist" errors. Verify before moving on from Phase 1.

- **Circular references between aspects and profiles [REVISIT]** — an aspect that reads `flake.lib.libsets.build` from a file that itself imports a profile creates a cycle. The fix is always the same: the value-holding file should not import any consumer. Keep `flake.lib.*` declarations leaf-shaped.

- **`hardware-configuration.nix` relocation [REVISIT at Phase 3]** — anything referencing the old path (`host/g14/hardware-configuration.nix`) breaks. Search the repo and any external scripts before the move. The new path is project-root `./hardware-configuration.nix`, referenced from `src/host/g14/g14.nix` as `../../../hardware-configuration.nix`.

- **agenix secret bootstrap [REVISIT at Phase 7]** — the first secret added with agenix requires a `secrets.nix` file at the agenix-conventional location declaring which identities can decrypt which secrets. Without this file, encryption is "encrypted to whom?" — undefined. Document the bootstrap step explicitly in the README.

- **`nh os switch` and `home-manager-as-nixos-module`** — `nh` rebuilds the NixOS system, which includes the nested HM evaluation. `nh home switch` is for *standalone* HM installs and would be the wrong command here. Confirm the justfile recipes call `nh os switch`, never `nh home switch`.

### Lower-attention items

- **Direnv hash-cache invalidation** — when a flake input updates, the direnv cache for that project doesn't auto-refresh. `direnv reload` is the manual fix. Worth a one-liner in the README.

- **Unstable overlay drift** — `nixpkgs-unstable` moves fast. A package that worked when added to `unstable.nix` may break on the next `flake update`. The mitigation is `nh os build` before `switch` — a broken unstable package fails the build, no activation.

- **Specialisations at boot vs at switch-to-configuration** — selecting a specialisation at the boot menu activates it for that boot only; the next boot reverts to the default unless rebuilt. Switching via `switch-to-configuration` at runtime is non-persistent in the same sense. The default profile is the one without a specialisation entry, and is what boots when no specialisation is chosen.

### What to prototype before committing

Nothing major. Two micro-spikes worth doing inside Phase 1 to derisk:

1. Confirm `import-tree` walks a directory containing one stub flake-parts module and the top-level config sees it. Five-minute test.
2. Confirm a `flake.modules.nixos.test` aspect declared in one file is readable as `self.nixosModules.test` from `flake.nix`. Five-minute test.

Both should pass trivially. If either fails, the assumptions about flake-parts integration are off and the spec needs revisiting before further work.

---

## Decisions reference (the alignment record)

For the trail-of-receipts: this plan was produced after a five-phase alignment loop. The locked decisions:

| # | Decision | Choice |
|---|---|---|
| 1 | Migration aggressiveness | Full dendritic |
| 2 | nh sequencing | Land separately, before the refactor |
| 3 | nh ergonomic depth | Full: enable + clean + flake; justfile rewritten to call nh |
| 4 | Walker library | `vic/import-tree` |
| 5 | Specialisations | Keep, with profile files spanning both classes |
| 6 | GC strategy | `nh clean` on a timer only |
| 7 | Direnv setup | Full: enable + nix-direnv + use_flake hash cache |
| 8 | Secrets manager | `agenix` |
| 9 | `disko` | **Deferred** (overrode initial recommendation) |
| 10 | Profile file shape | One file per profile, spanning both classes, named "profiles" (not "personas") |

Naming and structural choices applied: `src/` (not `modules/`), `users/yrrrrrf.nix` (not `lib/user.nix`), `host/` singular, no companion-shell-tool splitting, no CI directory, `unstable.nix` at root, shell scripts stay in place.

---

*End of plan.*