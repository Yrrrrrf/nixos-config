# NVIDIA / CUDA Configuration Audit — `yrrrrrf/nixos`

**Target host:** `g14` (Asus ROG Zephyrus G14 GA402X — AMD Ryzen + NVIDIA RTX dGPU, hybrid graphics)
**Flake base:** `nixos-25.11` (stable) + `nixos-unstable` overlay
**Audit date:** 2026-04-27
**Scope:** every file in the flake that references NVIDIA, CUDA, OpenGL, Nouveau, or PRIME.

---

## 1. Executive summary

The NVIDIA / CUDA configuration is **functionally working but architecturally fragmented**. Driver, GL/Vulkan stack, CUDA runtime, ML services (Ollama / Open WebUI), and GPU-related environment variables are spread across **8 distinct locations in 5 files**. Several of those locations contradict each other; one of them silently breaks PRIME offload; another puts a kernel-only package into a user package list where it has no effect.

The cause is not lack of skill — the modular layout (`system/`, `home/`, `host/`, `templates/`) is sound. The cause is **incremental accretion**: each time a new GPU concern came up (CUDA cache, Ollama, nix-ld libraries, dev-shell vars), it was added in the nearest convenient file rather than consolidated. The result is that no single file owns the GPU stack, so reasoning about it requires holding the whole tree in your head.

There is also one **structural redundancy** with `nixos-hardware`: the upstream `asus-zephyrus-ga402x-nvidia` module already configures most of what `system/nvidia.nix` re-declares (modesetting, PRIME bus IDs, dynamic boost, `services.xserver.videoDrivers`). The local module duplicates settings the upstream module already provides, and the host file imports both `-nvidia` and `-amdgpu` variants which are designed to be mutually exclusive.

---

## 2. The 8 touchpoints — where NVIDIA/CUDA lives today

| # | File | Lines (approx.) | What it declares |
|---|------|---|---|
| 1 | `flake.nix` | 141–143 | `ollama-cuda`, `open-webui` pulled from `nixpkgs-unstable` via overlay |
| 2 | `host/g14/configuration.nix` | 2810–2811 | imports `nixos-hardware.nixosModules.asus-zephyrus-ga402x-{nvidia,amdgpu}` (BOTH) |
| 3 | `host/g14/configuration.nix` | 2818 | imports `../../system/nvidia.nix` |
| 4 | `host/g14/configuration.nix` | 2830–2831 | commented-out `hardware.graphics.enable` and `services.xserver.videoDrivers` |
| 5 | `system/core.nix` | 3066–3094 | commented-out `programs.nix-ld.libraries` blocks containing `linuxPackages.nvidia_x11` |
| 6 | `system/nvidia.nix` | full file | cuda-maintainers cachix, `allowUnfreePredicate`, `hardware.nvidia.*`, `programs.nix-ld.libraries` |
| 7 | `system/services.nix` | 3311–3318 | `services.ollama.acceleration = "cuda"` and `services.open-webui` |
| 8 | `home/modules/packages/development.nix` | 2051–2056 | `cudaPkgs` set: `cudatoolkit`, `cudnn`, `linuxPackages.nvidia_x11` |
| 9 | `home/profiles/dev.nix` | 2237–2284 | `LD_LIBRARY_PATH` injection, `__EGL_VENDOR_LIBRARY_JSON_FILE`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `linuxPackages.nvidia_x11` in `home.packages` |

(Touchpoints 2–9 are all on the active code path. Touchpoints 4 and 5 are dead but still occupy mental space.)

---

## 3. Bugs (functional defects, ordered by severity)

### Bug 1 — `__GLX_VENDOR_LIBRARY_NAME = "nvidia"` set globally for all GUI apps

**Where:** `home/profiles/dev.nix` line 2253, inside `home.sessionVariables`.
**What it does:** This variable is `libglvnd`'s instruction to pick the NVIDIA GLX implementation for *every* OpenGL application launched in the user's session.
**Why it's a bug:** The system is configured for a **hybrid laptop with an AMD iGPU and an NVIDIA dGPU**. The intended PRIME pattern on such systems is *offload* — the iGPU drives the compositor and most apps, the dGPU is woken on demand for specific workloads via the `nvidia-offload` wrapper or the `__NV_PRIME_RENDER_OFFLOAD=1` environment variable. Forcing `__GLX_VENDOR_LIBRARY_NAME=nvidia` globally bypasses that mechanism — every GL client tries to hit the dGPU, the dGPU never sleeps, and battery / thermals suffer.
**Severity:** High. This is the kind of bug that doesn't show up in `nixos-rebuild` output but shows up as 2-hour battery life.
**Related fact:** The NixOS wiki's `nvidia-offload` script sets these variables **only for the wrapped command**, not the session. That is the canonical pattern.

### Bug 2 — `__EGL_VENDOR_LIBRARY_JSON_FILE` pinned to a specific package path

**Where:** `home/profiles/dev.nix` line 2251.
**What it does:** Points EGL's vendor selector at exactly one JSON file inside the `linuxPackages.nvidia_x11` store path.
**Why it's a bug:** Two reasons. First, it has the same "force everything to NVIDIA" effect as Bug 1, just for EGL instead of GLX. Second, it bypasses the system-managed `/run/opengl-driver/share/glvnd/egl_vendor.d/` directory that NixOS populates when `hardware.graphics.enable` is on. That directory is the union of all installed vendors — pointing past it forfeits any cooperation with the iGPU's EGL implementation, and on driver upgrade the path can go stale.
**Severity:** High. Same offload-defeat as Bug 1.

### Bug 3 — `pkgs.linuxPackages.nvidia_x11` placed in `home.packages`

**Where:** `home/profiles/dev.nix` line 2280.
**What it does:** Tries to install the NVIDIA driver package into the user's profile.
**Why it's a bug:** `linuxPackages.nvidia_x11` is a **kernel module package**. Its purpose is to be referenced by `boot.extraModulePackages` and to populate `/run/opengl-driver` via the system-level `hardware.nvidia` configuration. Installing it into `~/.nix-profile` does not expose its libraries to GL/Vulkan clients — those clients find libraries through the glvnd dispatcher and `/run/opengl-driver/lib`, both of which are system-managed. The line is dead weight: it pulls the package into the user closure but accomplishes nothing functionally.
**Severity:** Medium. No active harm, but creates the false impression that user-level NVIDIA library management is happening.

### Bug 4 — Both `asus-zephyrus-ga402x-nvidia` AND `asus-zephyrus-ga402x-amdgpu` imported simultaneously

**Where:** `host/g14/configuration.nix` lines 2810–2811.
**What it does:** Imports both upstream hardware variants of the same machine.
**Why it's a bug:** Per the nixos-hardware repository, these two modules are **mutually exclusive variants** — they are split precisely so that a user can choose AMD-only operation (dGPU disabled, longer battery) OR full hybrid operation with PRIME. Importing both means setting the same options from two sources. In the best case the values agree and Nix accepts it silently; in the worst case there is a conflict that surfaces as a confusing error at evaluation time. Even when it builds, it makes the configuration's intent unreadable: which mode is the system actually in?
**Severity:** Medium. Likely working today by coincidence, but a latent maintenance hazard.
**Related fact:** The earlier upstream form (`asus-zephyrus-ga402x.nvidia` and `asus-zephyrus-ga402x.amdgpu` as a single attrset) was deprecated in mid-2024 in favour of the two separate top-level entries — confirming the design intent that they are an either/or choice.

### Bug 5 — `hardware.graphics.enable` is never explicitly set anywhere

**Where:** Absent from `system/nvidia.nix`, `system/core.nix`, and `host/g14/configuration.nix`. The commented attempt at line 2830 is dead.
**What it does:** This option (renamed from `hardware.opengl.enable` in NixOS 24.11) enables the system-wide GL/Vulkan/EGL dispatch infrastructure (libglvnd, vendor JSON discovery, `/run/opengl-driver`).
**Why it's a bug:** The NixOS Wiki lists it as a **required** prerequisite for the NVIDIA proprietary driver. The configuration currently relies on it being set transitively by the upstream hardware module. That works, but it is brittle (upstream may refactor) and hostile to grep — there is no single line that tells a future reader "yes, OpenGL is on by design on this host."
**Severity:** Low (functional today) / Medium (documentation and robustness). Categorised as a bug because of the gap between *intent* and what the file says.

### Bug 6 — `enable32Bit` (formerly `driSupport32Bit`) is never set

**Where:** Absent throughout.
**What it does:** Enables 32-bit GL/Vulkan libraries — needed for Steam, Wine/Proton, older GL apps, some launchers.
**Why it's a bug:** Only a bug if the user runs 32-bit apps. The dev profile lists `unityhub`, which often pulls 32-bit dependencies for older targets, and Steam/gaming may enter the picture later. Worth a conscious decision rather than a silent omission.
**Severity:** Low (situational).

---

## 4. Redundancies (no functional defect, but duplicated truth)

### Redundancy A — Local NVIDIA settings duplicate what `nixos-hardware` already sets

**Where:** `system/nvidia.nix` `hardware.nvidia.*` block versus the upstream `asus-zephyrus-ga402x-nvidia` module.
**What's duplicated:** `modesetting.enable`, `prime.*BusId`, `dynamicBoost.enable`, the inclusion of `"nvidia"` in `services.xserver.videoDrivers`. The upstream module (visible in `nixos-hardware/asus/zephyrus/ga402x/nvidia/`) already provides these, building on the GA401 pattern that imports `common/gpu/nvidia/{prime.nix,ampere}` and sets bus IDs and modesetting with `lib.mkDefault`.
**Implication:** The local file is asserting the same values, sometimes with `mkForce` / direct assignment that overrides upstream's `mkDefault`. The override semantics work, but the local file becomes the authority for things the local file doesn't actually know — bus IDs in particular are hardware-specific and shouldn't be re-stated when the upstream module already has them right.

### Redundancy B — `nix-ld.libraries` declared (and commented) in two files

**Where:** `system/core.nix` (commented blocks at lines ~3066–3094) AND `system/nvidia.nix` (active). Both reference `linuxPackages.nvidia_x11`.
**Implication:** The commented version in `core.nix` is a leftover from an earlier iteration. It currently does nothing, but it is the kind of thing that gets uncommented in a hurry and then both files compete to define `programs.nix-ld.libraries`.

### Redundancy C — CUDA-related package set declared in `home/`, system services consuming CUDA in `system/`

**Where:** `home/modules/packages/development.nix` defines `cudaPkgs` (cudatoolkit, cudnn, nvidia_x11), and `system/services.nix` enables `services.ollama.acceleration = "cuda"`. Neither file references the other.
**Implication:** "CUDA on this machine" is not something a future reader can find by opening one file. The system *uses* CUDA in three different identities — kernel/driver (system), service (`ollama`), per-user development libraries (home) — and each identity declares its CUDA needs locally. They aren't in conflict, but the absence of a hub means a CUDA-version bump requires editing three files.

### Redundancy D — `ollama-cuda` overlaid in `flake.nix` is unused on the active path

**Where:** `flake.nix` overlay at line 142 exposes `pkgs.ollama-cuda`, but `system/services.nix` enables `services.ollama` (which uses regular `pkgs.ollama` with the `acceleration = "cuda"` option) — not the `ollama-cuda` package.
**Implication:** The overlay'd `ollama-cuda` is reachable as a package but no longer the system's path to CUDA-accelerated Ollama. Either the overlay is leftover from an earlier approach, or it's intentional standby for `nix shell` use — the configuration doesn't say which.

### Redundancy E — Dead commented blocks across multiple files

`host/g14/configuration.nix` lines 2825–2832 (commented `permittedInsecurePackages`, `hardware.graphics.enable`, `videoDrivers`), `system/core.nix` lines 3068–3094 (commented `nix-ld.libraries`), `flake.nix` lines 124–127 and 145–147 (`ciscoPacketTracer9` overrides). Each one represents a path not taken, but none is annotated with *why* it was abandoned. Dead code without justification erodes the modular design's biggest asset — that you can read one file and know what it does.

---

## 5. Architectural observations (not bugs, but tensions)

### Observation 1 — `home/profiles/dev.nix` is doing system-level work

The dev profile injects `LD_LIBRARY_PATH` with CUDA libraries, sets GL vendor variables, and lists a kernel-side package. These are **not user preferences** — they are system-wide GPU stack configuration that happens to be expressed at the home-manager layer. The right home for them is either `system/nvidia.nix` (system stack), `programs.nix-ld.libraries` (non-Nix binary fallback), or an in-project `nix develop` shell (per-project CUDA). Putting them in the home profile means that whether CUDA "works" depends on which home profile is active — `dev` works, `minimal` doesn't — which is surprising for a system-level concern.

### Observation 2 — Global `LD_LIBRARY_PATH` injection conflicts with the Nix philosophy

Setting `LD_LIBRARY_PATH` globally is the standard escape hatch for non-Nix binaries, but doing it at the user-session level means it leaks into every `nix develop` shell, every dev tool, every subprocess. The reproducibility win of `nix develop` is partially neutralised when the host already injects libraries at the session level. The CUDA wiki page recommends per-shell `shellHook` injection or a per-project FHS env precisely to keep CUDA scoped.

### Observation 3 — No specialisation for PRIME mode

The host config already uses NixOS specialisations for `dev` and `minimal` home profiles. The same mechanism is the documented way to switch PRIME modes (offload for battery, sync for docked / heavy GPU). It would compose naturally with the existing pattern — one `specialisation."sync"` entry alongside the existing two — but isn't there yet. This is a missing feature rather than a bug.

### Observation 4 — `allowUnfreePredicate` in `system/nvidia.nix` is shadowed by `allowUnfree = true` in the host

`system/nvidia.nix` defines a tight `allowUnfreePredicate` listing `nvidia-x11`, `nvidia-settings`, `cudatoolkit` — a deliberately surgical permission. But `host/g14/configuration.nix` line 2823 sets `nixpkgs.config.allowUnfree = true;` globally, which makes the predicate moot. Either the global flag should go (and the predicate be expanded to cover everything actually needed: drivers, CUDA stack, Steam, jetbrains, Unity, vscode, etc.), or the predicate should be deleted as misleading. Right now the file *says* "minimal unfree surface" while the host *actually* allows everything.

---

## 6. What the resources actually say (canonical references)

The audit above is grounded in the following primary sources. Each fact in §3 maps back to one or more of these.

- **NixOS Wiki — NVIDIA** (`https://wiki.nixos.org/wiki/NVIDIA`)
  - `hardware.graphics.enable` (formerly `hardware.opengl.enable` until 24.11) is required for the proprietary driver.
  - `services.xserver.videoDrivers = [ "nvidia" ]` is required for kernel modules from NVIDIA.
  - PRIME offload requires `hardware.nvidia.modesetting.enable = true` and `hardware.nvidia.prime.offload.enable = true`, plus the Intel/AMD and NVIDIA bus IDs.
  - The `nvidia-offload` wrapper (generated when `enableOffloadCmd = true`) sets `__NV_PRIME_RENDER_OFFLOAD`, `__NV_PRIME_RENDER_OFFLOAD_PROVIDER`, `__GLX_VENDOR_LIBRARY_NAME`, `__VK_LAYER_NV_optimus` **for the wrapped command only**. This is the canonical pattern for hybrid laptops.
  - Specialisations are the documented mechanism for switching between offload-mode and sync-mode at boot.
  - Wayland requires KMS (`hardware.nvidia.modesetting.enable = true`); explicit sync is supported on driver ≥ 555 and strongly recommended for Hyprland.

- **NixOS Wiki — CUDA** (`https://wiki.nixos.org/wiki/CUDA`)
  - The `cuda-maintainers.cachix.org` binary cache provides prebuilt CUDA artifacts. (Already configured in `system/nvidia.nix` — credit where due.)
  - Per-project CUDA is best done through `mkShell` / FHS env / a flake `devShell` with `LD_LIBRARY_PATH` set in `shellHook`, **not** at the session level.
  - `config.cudaSupport = true` and `config.cudaVersion = "12"` can be passed to `import nixpkgs` inside a flake to switch CUDA-aware builds globally for that shell.

- **`nixos-hardware` repository** (`https://github.com/NixOS/nixos-hardware`)
  - `asus-zephyrus-ga402x-nvidia` and `asus-zephyrus-ga402x-amdgpu` are the current top-level entries; the older attrset form is deprecated.
  - The `-nvidia` profile composes `common/cpu/amd`, `common/gpu/amd`, `common/gpu/nvidia/prime.nix`, `common/gpu/nvidia/ampere`, and laptop common modules. It sets bus IDs, modesetting, dynamic boost, and `asusd`.
  - Most options are set with `lib.mkDefault`, which means a local module can override them — but should only do so deliberately.

- **Vimjoyer — Local LLMs on NixOS** (`youtube.com/watch?v=5T52jNXzqIU`)
  - This is the source of the current `services.ollama` + `services.open-webui` + cuda-maintainers cachix configuration. The video does **not** prescribe the global `LD_LIBRARY_PATH` injection or the GL vendor variables — those were added independently.

- **Vimjoyer — Gaming on NixOS** (`github.com/vimjoyer/nixos-gaming-video`)
  - Demonstrates the `specialisation` pattern for switching between offload (default, battery) and sync (gaming-time, performance).
  - Uses `hardware.graphics.{enable, enable32Bit}` together — relevant to Bug 6.

---

## 7. Severity ranking and recommended order of operations

This is a checklist of what to address first, ordered by user-visible impact. **Implementations are deliberately not given here** — the goal of this document is to enumerate the problem space so that a clean implementation can be designed in a separate pass.

1. **Bug 1 + Bug 2** (forced GL vendor) — battery / thermal impact, fix first.
2. **Bug 4** (double hardware-module import) — latent eval-time hazard.
3. **Bug 3** (kernel package in home.packages) — closure cleanliness.
4. **Bug 5 + Bug 6** (`hardware.graphics` not explicit) — robustness and 32-bit decision.
5. **Redundancy A** (local config duplicating upstream) — collapse to single ownership.
6. **Redundancy C** (CUDA in three places) — pick one home for "this machine has CUDA."
7. **Observation 1 + 2** (system concerns in home profile, global `LD_LIBRARY_PATH`) — restructure CUDA into `nix develop` shells.
8. **Redundancy E** (dead commented code) — remove or annotate.
9. **Observation 3** (PRIME specialisation) — feature add, optional.
10. **Observation 4** (`allowUnfree` vs predicate) — pick one philosophy and apply it consistently.

---

## 8. What the consolidated structure should *describe* (not how to implement it)

A future `system/nvidia.nix` should be the **single source of truth** for everything GPU-related on this host. By the principle of one-file-one-concern from the existing modular layout, that file should answer the following questions, and no other file should answer them:

- Which upstream hardware module describes this machine? (One import.)
- Is the proprietary driver enabled? Which branch? Open or closed kernel modules?
- Is OpenGL/Vulkan/EGL dispatch on? Is 32-bit support on?
- Is PRIME on? Which mode by default? Which alternate modes are available as boot specialisations?
- Is power management on? Are suspend/resume workarounds needed?
- Is the CUDA cache trusted? Which unfree packages are allowed?
- Are there nix-ld libraries needed for non-Nix CUDA consumers?
- Are GPU-accelerated system services (Ollama, Open WebUI) enabled here?

The home profile (`dev.nix`) should then own only **user-level** GPU concerns, which on a properly-configured system reduces to approximately zero — the GL stack, CUDA libraries, and vendor selection are system concerns. Per-project CUDA work belongs in `templates/cuda/flake.nix` (which does not yet exist) or inside individual project flakes.

The host file (`host/g14/configuration.nix`) should import `system/nvidia.nix` and nothing else GPU-related. The lines currently importing the two hardware modules disappear because `system/nvidia.nix` imports the single correct one.

After this restructuring, "where is NVIDIA configured?" has one answer: `system/nvidia.nix`. That is the test of whether the consolidation succeeded.

---

## 9. Out of scope for this document

- **Specific code.** No `.nix` snippets are prescribed here. The previous conversation contains a draft of the consolidated `system/nvidia.nix`; this document is the *justification* for that draft, not a substitute for it.
- **CUDA dev-shell template.** Mentioned as a structural recommendation but not designed here.
- **Kernel parameter tuning** (`nvidia.NVreg_TemporaryFilePath`, suspend/resume workarounds, `module_blacklist=amdgpu`) — only relevant if the user encounters the specific symptoms documented in the wiki troubleshooting section.
- **Wayland / Hyprland explicit-sync configuration** — depends on the active driver version and is a separate audit.
- **AMD iGPU configuration** — out of scope; addressed implicitly by the `-nvidia` upstream module which composes `common/gpu/amd`.

---

## 10. Glossary

- **PRIME** — NVIDIA's mechanism for hybrid-graphics laptops, allowing the iGPU and dGPU to cooperate.
- **PRIME offload** — iGPU drives the desktop, dGPU sleeps until invoked. Best for battery.
- **PRIME sync** — dGPU renders everything, iGPU only displays. Best for performance / external monitors. X11-only.
- **PRIME reverse-sync** — dGPU is primary; iGPU follows. Experimental.
- **glvnd / libglvnd** — the dispatch library that lets multiple GL vendor implementations coexist. `__GLX_VENDOR_LIBRARY_NAME` and `__EGL_VENDOR_LIBRARY_JSON_FILE` are its selection knobs.
- **modesetting** — kernel mode setting; lets the kernel set display modes directly. Required for Wayland.
- **nix-ld** — a wrapper that lets non-Nix-built dynamically-linked binaries find libraries from the Nix store. Common need for Python wheels with native CUDA bindings.
- **nixos-hardware** — community-maintained repository of per-device modules that handle hardware quirks.
- **specialisation** — a NixOS feature that creates an alternate boot entry with config overrides. Already used in this flake for `dev` / `minimal` home profiles.
