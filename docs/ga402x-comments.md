# `nixos-hardware/asus/zephyrus/ga402x` — Module Deep Dive

**Subject:** the upstream `nixos-hardware` module tree for the Asus ROG Zephyrus G14 GA402X (2023)
**Source commit:** `2096f3f411ce46e88a79ae4eafcfc9df8ed41c61`
**Path:** `asus/zephyrus/ga402x/`
**Audience:** someone who imports `inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia` (or the `-amdgpu` variant) and wants to know *exactly* what they just inherited.

---

## 1. What `nixos-hardware` is and why this matters

`nixos-hardware` is a community-maintained repository of NixOS modules, one (or several) per device, that encode the quirks and tested settings needed to make Linux behave correctly on specific hardware. Importing the right module replaces the equivalent of "an evening of forum-archaeology and trial-and-error" with a single line in your flake's `imports`.

For the GA402X specifically, the module captures: the AMD CPU configuration, the AMD iGPU plus NVIDIA dGPU PRIME wiring, ASUS-specific daemons (`asusd`, `supergfxd`), kernel parameters tuned for this chassis's suspend behavior, the bus IDs of both GPUs (which are *physical facts* about how the silicon is wired), kernel-version-conditional workarounds for keyboard auto-suspend, and Mediatek WiFi roaming tweaks. None of this is unique to NixOS — Arch, Fedora, and OpenSUSE users on the asus-linux project arrive at similar settings — but `nixos-hardware` codifies them as composable Nix modules.

Concretely: when you write

```nix
imports = [ inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia ];
```

you are not importing one file. You are importing the **root of a tree of about eight Nix modules** that compose into a single configuration. This document traces that tree exhaustively.

---

## 2. The directory layout

```
asus/zephyrus/ga402x/
├── ATTR-SET-DEPRECATION.md     ← historical note, see §3
├── default.nix                 ← deprecated trap (throws on import)
├── shared.nix                  ← chassis-level config, true for both GPU paths
├── amdgpu/
│   └── default.nix             ← AMD-only path: dGPU disabled
└── nvidia/
    └── default.nix             ← AMD iGPU + NVIDIA dGPU + PRIME (the path you want)
```

Two leaf entry points (`amdgpu/` and `nvidia/`) both import `shared.nix`. `shared.nix` and `nvidia/default.nix` between them import several modules from the `common/` tree (`common/cpu/amd`, `common/gpu/nvidia/prime.nix`, etc.). The full transitive set is what you actually get.

---

## 3. The deprecation trap (`default.nix`)

The bare entry `asus-zephyrus-ga402x` (no `-amdgpu` or `-nvidia` suffix) used to expose an attribute set with `.amdgpu` and `.nvidia` keys, so users could write `imports = [ asus-zephyrus-ga402x.nvidia ]`. PR #1046 in the upstream repo changed how `nixos-hardware` exports modules (to paths instead of attrsets), which broke that pattern. PR #1053 then replaced the attrset with two separate top-level entries (`asus-zephyrus-ga402x-amdgpu` and `asus-zephyrus-ga402x-nvidia`) and made the bare entry throw a deprecation error:

```nix
{
  assertions = [{
    assertion = false;
    message = "Importing asus/zephyrus/ga402x/ (default.nix) directly is deprecated! …";
  }];
}
```

This means **the only supported imports today are the two suffixed entries**. Importing the bare entry will fail evaluation with a clear message.

It also reinforces the design intent: the AMD-only and AMD+NVIDIA paths are **mutually exclusive variants of the same machine**. You pick one and import it.

---

## 4. `shared.nix` — the chassis layer

`shared.nix` describes everything that is true about a GA402X **regardless of which GPU configuration you choose**. Both `amdgpu/default.nix` and `nvidia/default.nix` import it.

### 4.1 What it imports

```nix
imports = [
  ../../../common/cpu/amd            # AMD CPU support (microcode, kvm-amd, ucode loader)
  ../../../common/cpu/amd/pstate.nix # amd_pstate=active for modern P-state driver
  ../../../common/gpu/amd            # iGPU support (amdgpu in initrd, GL stack)
  ../../../common/pc/laptop          # generic laptop power and lid handling
  ../../../common/pc/ssd             # weekly fstrim
];
```

Note that `common/gpu/amd` is imported here, **not just on the AMD-only path**. The iGPU is always present in this machine — even in the NVIDIA-enabled configuration, the AMD iGPU runs the desktop. That's the entire point of PRIME offload.

### 4.2 Boot configuration

```nix
boot = {
  kernelModules = [ "kvm-amd" ];
  kernelParams = [
    "mem_sleep_default=deep"           # use deep S3-style suspend by default
    "pcie_aspm.policy=powersupersave"  # aggressive PCIe link power saving
  ];
};
```

`mem_sleep_default=deep` is significant: the default on many modern laptops is `s2idle` (modern standby), which on Linux can drain battery faster than expected because background activity continues. Forcing `deep` gives you traditional S3 suspend, which is much closer to "actually off" power-wise. This is the kernel parameter that makes "close lid for 8 hours, open and find non-trivial battery left" actually work on this laptop.

`pcie_aspm.policy=powersupersave` is the most aggressive ASPM (Active State Power Management) profile. It lets PCIe links enter the deepest power-saving state when idle. On laptops with NVMe SSDs and discrete GPUs this is worth real wattage at idle.

### 4.3 Services

```nix
services = {
  asusd.enable = mkDefault true;       # ASUS daemon
  supergfxd.enable = mkDefault true;   # GPU mode switcher daemon
  udev.extraHwdb = ''
    evdev:name:*:dmi:bvn*:bvr*:bd*:svnASUS*:pn*:*
    KEYBOARD_KEY_ff31007c=f20  # fixes mic-mute button
  '';
};
```

**`asusd`** (from the asus-linux project) handles fan curves, charge limits, keyboard backlight, RGB, the ROG key, Aura sync, performance profile switching (Quiet / Balanced / Performance), and battery charge thresholds. Without it, many of the laptop's hardware features are inaccessible from Linux.

**`supergfxd`** is the GPU mode switcher. It exposes `supergfxctl` on the command line, which can switch between `Hybrid` (default — both GPUs available, PRIME offload), `Integrated` (dGPU physically powered off via the MUX, maximum battery), `Dedicated` (dGPU drives the internal display directly, maximum performance, requires reboot), `AsusMuxDgpu` (variant), and `Vfio` (binds dGPU to vfio for VM passthrough). This is the runtime alternative to NixOS specialisations for switching GPU modes.

The udev hwdb rule remaps the mic-mute key's scancode to `f20`, making it usable as a hotkey.

### 4.4 Options exposed (the smart-default pattern)

`shared.nix` defines two options under `hardware.asus.zephyrus.ga402x`:

```nix
options.hardware.asus.zephyrus.ga402x = {
  keyboard.autosuspend.enable = mkEnableOption "…" // {
    default = versionAtLeast config.boot.kernelPackages.kernel.version "6.9";
  };
  ite-device.wakeup.enable = mkEnableOption "…";
};
```

The first option is **kernel-version-conditional**: on kernels ≥ 6.9 the underlying USB-keyboard autosuspend bug is fixed, so autosuspend is enabled by default; on older kernels it's disabled by default. This is the kind of conditional logic that owners of this laptop on other distros maintain by hand in udev rules — `nixos-hardware` does it for you, reading your kernel package's version at evaluation time.

The second option (`ite-device.wakeup.enable`) is for an obscure "8295 ITE Device" that, on certain kernel versions, causes the laptop to immediately wake after suspend. Default: disabled.

### 4.5 Conditional config blocks (`mkMerge` + `mkIf`)

The body of the file is a single `mkMerge` containing four blocks:

1. **Always-applied block** — the boot/services/udev configuration above.
2. **`mkIf (!cfg.keyboard.autosuspend.enable)`** — adds a udev rule that disables USB autosuspend on the ASUS N-KEY device (`idVendor=0b05`, `idProduct=19b6`). Only applied when the option is `false` (i.e., on old kernels).
3. **`mkIf (!cfg.ite-device.wakeup.enable)`** — adds a udev rule disabling power wakeup on the 8295 ITE device (`idVendor=0b05`, `idProduct=193b`). Applied by default.
4. **`mkIf (config.networking.wireless.iwd.enable && config.networking.wireless.scanOnLowSignal)`** — Mediatek WiFi roaming tuning. Applied only if you opted into iwd with low-signal scanning.

The pattern is: declare options with smart defaults, then apply the actual settings conditionally. The user can override defaults from their own configuration (e.g., `hardware.asus.zephyrus.ga402x.keyboard.autosuspend.enable = false;`).

### 4.6 What `shared.nix` does NOT do

- It does **not** import any `common/gpu/nvidia/*` module — that's a leaf-module concern.
- It does **not** set `services.xserver.videoDrivers`.
- It does **not** configure any NVIDIA-specific options.

This separation is what makes the AMD-only path work cleanly: the AMD-only leaf only adds AMD-specific kernel-param options on top of `shared.nix` and never touches NVIDIA at all.

---

## 5. `nvidia/default.nix` — the NVIDIA-enabled path

This is what your flake actually imports. The file is short because all the heavy lifting is in `shared.nix` and the `common/` modules.

### 5.1 Imports

```nix
imports = [
  ../shared.nix
  ../../../../common/gpu/nvidia/prime.nix      # generic PRIME wiring
  ../../../../common/gpu/nvidia/ada-lovelace   # generation-specific tweaks
];
```

There's a small inline comment noting that `prime.nix` itself imports `common/gpu/nvidia` (the base NVIDIA module), so the leaf module doesn't need to import it directly.

The split between `prime.nix` (generic PRIME for any laptop) and `ada-lovelace` (generation-specific) is `nixos-hardware`'s pattern for separating "what's true for all NVIDIA hybrid laptops" from "what's true for *this generation* of NVIDIA chip." For older laptops the second import would be `ampere`, `turing`, `pascal`, etc.

### 5.2 GPU architecture: Ada Lovelace, not Ampere

The GA402X 2023 ships with the **NVIDIA GeForce RTX 4060 Mobile** (per the inline comment in the upstream file). The 40-series is **Ada Lovelace**, NVIDIA's architecture launched in late 2022. The previous generation (RTX 30-series) is Ampere. Importing `common/gpu/nvidia/ada-lovelace` selects the correct driver branch and any architecture-specific tweaks for this generation. (At driver level: Ada cards require driver ≥ 535, with significant Wayland/explicit-sync improvements landing in 555+.)

### 5.3 Driver and module configuration

```nix
boot.blacklistedKernelModules = [ "nouveau" ];
services.xserver.videoDrivers = mkDefault [ "nvidia" ];
hardware.amdgpu.initrd.enable = mkDefault true;
```

- **Blacklisting `nouveau`** is hardcoded (no `mkDefault`). The proprietary and open-source NVIDIA drivers cannot coexist; loading nouveau when you've configured the proprietary stack causes problems.
- **`videoDrivers = [ "nvidia" ]`** — note this is *just* `"nvidia"`, not `[ "modesetting" "nvidia" ]` or `[ "amdgpu" "nvidia" ]`. Under Wayland (which doesn't use Xorg drivers anyway, only XWayland) this is fine. Under pure Xorg with PRIME offload, the wiki recommends listing both because Xorg needs to know about the iGPU as well; upstream's choice here is Wayland-optimized. Override locally if you run pure Xorg.
- **`amdgpu.initrd.enable = true`** — loads the iGPU driver in the initramfs, so the iGPU is ready before userspace starts. Important because the iGPU drives the display from boot.

### 5.4 `hardware.nvidia.*` block

```nix
hardware.nvidia = {
  modesetting.enable = true;        # hardcoded — Wayland requires KMS
  nvidiaSettings = mkDefault true;  # nvidia-settings GUI
  prime = {
    offload = {
      enable = mkDefault true;
      enableOffloadCmd = mkDefault true;
    };
    amdgpuBusId = "PCI:101:0:0";    # hardcoded — physical fact
    nvidiaBusId = "PCI:1:0:0";      # hardcoded — physical fact
  };
  powerManagement = {
    # enable = true;       ← deliberately commented
    # finegrained = true   ← deliberately commented
  };
};
```

A few things worth dwelling on:

**`modesetting.enable = true` is hardcoded, not `mkDefault`.** Disabling KMS would break Wayland on this GPU. Upstream is asserting this is non-negotiable.

**Bus IDs are hardcoded.** They are not configuration choices — they are physical facts about how the silicon is wired into the PCIe topology of this specific motherboard. The format `PCI:<bus>@<domain>:<device>:<func>` (or `PCI:<bus>:<device>:<func>` when domain is implicit) is what `xorg.conf` expects. Decimal, not hexadecimal. The amdgpu bus ID being `101` is unusual (most laptops have it at a low number) and reflects the GA402X's specific topology.

**`prime.offload.enable = mkDefault true`** sets the default mode. Offload means: iGPU runs the desktop, dGPU sleeps until invoked via `nvidia-offload <command>`. This is the battery-friendly default. To switch to sync mode (dGPU drives everything, better performance, X11-only), you override this and set `prime.sync.enable = true`. Sync and offload are mutually exclusive — the wiki spells this out explicitly.

**`enableOffloadCmd = mkDefault true`** generates the `nvidia-offload` wrapper script in `$PATH`. Running `nvidia-offload glxgears` sets the four NVIDIA-specific environment variables (`__NV_PRIME_RENDER_OFFLOAD=1`, `__NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `__VK_LAYER_NV_optimus=NVIDIA_only`) **for that one process only**, then runs `glxgears` on the dGPU. The script exists precisely so that you don't set those variables globally — setting them globally defeats offload by forcing every GL app to wake the dGPU.

**`powerManagement.enable` is deliberately disabled.** The comment is explicit: `# This is unreliable on the 4060; works a few times, then hangs:`. The maintainer tested this option on the exact silicon this module targets and found it causes suspend/resume hangs. Leaving it commented is a *negative* recommendation — "don't enable this, it's broken on this chip." Anyone setting `hardware.nvidia.powerManagement.enable = true;` in their local config is overriding upstream's tested-bad finding with their own untested guess. (This is, unfortunately, a common copy-paste from the wiki, where the option is recommended generically.)

### 5.5 What this module does NOT cover

- **CUDA toolkit / cuDNN** — those are application-level concerns, not driver concerns. Use `cudaPackages.*` from nixpkgs, ideally inside a per-project `nix develop` shell.
- **`hardware.graphics.enable`** — set transitively by `common/gpu/nvidia/prime.nix`. Worth setting explicitly in your local config for grep-ability, but not strictly required.
- **`enable32Bit`** — for 32-bit GL (Steam, Wine). Off by default; opt in locally if you need it.
- **CUDA binary cache** (`cuda-maintainers.cachix.org`) — application-layer optimization, not the module's concern.
- **`services.ollama` / `services.open-webui`** — applications that *use* CUDA, not driver setup.

These are all things your local `system/nvidia.nix` should own. The upstream module's job stops at "the kernel can talk to the GPU and X/Wayland sees it correctly."

---

## 6. `amdgpu/default.nix` — the AMD-only path (for context)

You don't import this, but understanding what it does clarifies the design.

```nix
imports = [ ../shared.nix ];

options.hardware.asus.zephyrus.ga402x.amdgpu = {
  recovery.enable    = mkEnableOption "…" // { default = false; };
  sg_display.enable  = mkEnableOption "…" // { default = true;  };
  psr.enable         = mkEnableOption "…" // { default = true;  };
};

config = mkMerge [
  (mkIf cfg.amdgpu.recovery.enable     { boot.kernelParams = [ "amdgpu.gpu_recovery=1" ]; })
  (mkIf (!cfg.amdgpu.sg_display.enable){ boot.kernelParams = [ "amdgpu.sg_display=0" ]; })
  (mkIf (!cfg.amdgpu.psr.enable)       { boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ]; })
];
```

That is the entire file. It's a thin layer of AMD-iGPU-specific kernel parameter toggles, all of which are off-by-default unless you explicitly opt in (or out) for a specific behavior:

- **`recovery.enable`** — adds `amdgpu.gpu_recovery=1`, which can help with kernel hangs during suspend. Off by default.
- **`sg_display.enable`** — defaults to **on**, meaning **no kernel param is added**. Setting it to false adds `amdgpu.sg_display=0`, which can fix flickering on certain panels.
- **`psr.enable`** — same pattern. Defaults to on, no param added. Setting to false adds `amdgpu.dcdebugmask=0x10`, also for flickering issues.

Note this module **never touches NVIDIA**. Importing it gives you a system where the dGPU is essentially invisible to the OS — the kernel doesn't load the NVIDIA modules at all. This is what you'd use if you wanted maximum battery life and never needed CUDA or GPU compute.

### 6.1 If you imported BOTH `-amdgpu` AND `-nvidia` (your current state)

A previous audit document flagged this as a bug. With the actual upstream source visible, the picture is clearer:

- Both leaves import `shared.nix`, but Nix module imports are deduplicated by file path, so `shared.nix` is only evaluated once. No conflict.
- `-amdgpu` adds the three `amdgpu.*` options under `hardware.asus.zephyrus.ga402x.amdgpu` to the option tree. With defaults (`recovery=false`, `sg_display=true`, `psr=true`), **no extra kernel parameters are emitted**, because the conditional blocks only fire when the options take their non-default values.
- `-nvidia` does its NVIDIA-enabling work as described above.

**Net effect at default settings: importing both is harmless today.** It adds some unused options to your config tree but doesn't change any actual setting. The earlier audit overstated this. The real issue is **semantic** — the modules are designed as either/or, importing both signals confused intent rather than functional breakage. Pick one.

---

## 7. The transitive `common/` modules

Following all the imports, the modules you transitively pull in are roughly:

| Module | What it does |
|---|---|
| `common/cpu/amd` | AMD microcode updates (`hardware.cpu.amd.updateMicrocode = true`), `kvm-amd` kernel module, ucode loader. |
| `common/cpu/amd/pstate.nix` | Enables `amd_pstate=active` kernel parameter for the modern P-state driver. Better than legacy `acpi-cpufreq` on Zen 3+ CPUs. |
| `common/gpu/amd` | `boot.initrd.kernelModules = [ "amdgpu" ]`, GL stack hints, ensures `mesa` is in the system. |
| `common/pc/laptop` | Generic laptop power management, lid-switch handling, sane defaults for `services.upower`, possibly `services.tlp` or `power-profiles-daemon`. |
| `common/pc/ssd` | `services.fstrim.enable = true` with weekly schedule. |
| `common/gpu/nvidia` | Base NVIDIA module (loaded transitively via `prime.nix`). Sets up the kernel module package selection, enables the basic driver. |
| `common/gpu/nvidia/prime.nix` | Generic PRIME infrastructure: ensures `hardware.graphics.enable = true`, sets up the offload service plumbing, generates the `nvidia-offload` wrapper when enabled. |
| `common/gpu/nvidia/ada-lovelace` | Generation-specific: ensures the driver branch is appropriate for Ada cards (≥ 535). |

The exact contents of each can be inspected at `github.com/NixOS/nixos-hardware/blob/master/<path>`, but the names give you the contract.

---

## 8. Composition diagram

When your flake imports `asus-zephyrus-ga402x-nvidia`, the module system flattens this tree into a single configuration:

```
your flake.nix
  └─ host/g14/configuration.nix
       └─ imports asus-zephyrus-ga402x-nvidia
            ├─ ga402x/nvidia/default.nix       ── NVIDIA + PRIME offload + bus IDs
            │    ├─ ga402x/shared.nix          ── chassis, asusd, supergfxd, kernel params
            │    │    ├─ common/cpu/amd
            │    │    ├─ common/cpu/amd/pstate.nix
            │    │    ├─ common/gpu/amd
            │    │    ├─ common/pc/laptop
            │    │    └─ common/pc/ssd
            │    ├─ common/gpu/nvidia/prime.nix       ── hardware.graphics.enable, etc.
            │    │    └─ common/gpu/nvidia            ── base NVIDIA driver setup
            │    └─ common/gpu/nvidia/ada-lovelace    ── correct driver branch for 4060
            │
            └─ then YOUR system/nvidia.nix overlays on top
```

The right-hand column tells you what each layer contributes that the layers below it don't.

---

## 9. What you actually inherit (final state at evaluation)

After flattening, the configuration includes — among many other things — the following settings that you did **not** write yourself but now apply to your system:

**Kernel and boot:**
- `kvm-amd` loaded
- `amdgpu` in initrd
- Kernel params: `mem_sleep_default=deep`, `pcie_aspm.policy=powersupersave`, `amd_pstate=active`
- `nouveau` blacklisted

**CPU:**
- AMD microcode auto-update enabled
- `amd_pstate=active` (modern frequency scaling)

**GPU stack:**
- `hardware.graphics.enable = true` (transitive, via `prime.nix`)
- `services.xserver.videoDrivers = [ "nvidia" ]`
- `hardware.nvidia.modesetting.enable = true` (KMS for Wayland)
- `hardware.nvidia.nvidiaSettings = true`
- `hardware.nvidia.prime.offload.enable = true`
- `hardware.nvidia.prime.offload.enableOffloadCmd = true` (generates `nvidia-offload`)
- `hardware.nvidia.prime.amdgpuBusId = "PCI:101:0:0"`
- `hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0"`
- `hardware.nvidia.powerManagement` left disabled (deliberately)
- Driver branch suitable for Ada Lovelace
- `hardware.amdgpu.initrd.enable = true`

**Services:**
- `asusd.enable = true` (fans, charge limits, RGB, performance profiles)
- `supergfxd.enable = true` (`supergfxctl` GPU mode switching)
- `fstrim.enable = true` (weekly TRIM)
- `upower` and laptop power management defaults from `common/pc/laptop`

**udev:**
- Mic-mute key remapping
- 8295 ITE device wakeup disabled (default)
- N-KEY autosuspend disabled on kernels < 6.9 (auto)

**Networking (only if you opted in):**
- Mediatek-friendly iwd roaming thresholds — applied only when both `iwd.enable` and `scanOnLowSignal` are true

This list is what would otherwise have been forty or fifty lines of configuration you'd write yourself. Importing the module reduces it to one line.

---

## 10. The `mkDefault` / hardcoded distinction (and why it matters)

A recurring pattern is whether a value is set with `mkDefault` (overridable freely, "this is our suggestion") or as a plain assignment (overridable but signals "we tested this, override at your own risk"). Quick reference:

**Hardcoded by upstream (override only with caution):**
- `boot.blacklistedKernelModules = [ "nouveau" ]`
- `boot.kernelModules = [ "kvm-amd" ]`
- `boot.kernelParams = [ "mem_sleep_default=deep" "pcie_aspm.policy=powersupersave" ]`
- `hardware.nvidia.modesetting.enable = true`
- `hardware.nvidia.prime.amdgpuBusId = "PCI:101:0:0"`
- `hardware.nvidia.prime.nvidiaBusId = "PCI:1:0:0"`
- udev rules for mic-mute, 8295 ITE, N-KEY autosuspend

**`mkDefault` (free to override):**
- `services.asusd.enable`
- `services.supergfxd.enable`
- `services.xserver.videoDrivers`
- `hardware.amdgpu.initrd.enable`
- `hardware.nvidia.nvidiaSettings`
- `hardware.nvidia.prime.offload.enable`
- `hardware.nvidia.prime.offload.enableOffloadCmd`

If a setting in your local config conflicts with a hardcoded upstream setting, you need `lib.mkForce` to override it. If it conflicts with an `mkDefault`, simple assignment wins.

---

## 11. What this means for your local `system/nvidia.nix`

With the upstream module's contents now visible, your local file's lines fall into four categories:

**Category A — Already done by upstream, your line is redundant:**
- `hardware.nvidia.modesetting.enable = true;` — upstream hardcodes this
- `hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;` — upstream's default branch already

**Category B — Overrides upstream's deliberate non-setting:**
- `hardware.nvidia.powerManagement.enable = true;` — upstream deliberately leaves this off because it hangs the 4060

**Category C — Outside upstream's scope, legitimately yours:**
- cuda-maintainers cachix configuration
- `nixpkgs.config.allowUnfreePredicate`
- `programs.nix-ld.{enable,libraries}` for non-Nix CUDA consumers
- (And `services.ollama` / `services.open-webui` if moved here from `services.nix`)

**Category D — Optional extensions of upstream:**
- `hardware.graphics.enable32Bit = true` if you want 32-bit GL (Steam, Wine)
- `hardware.nvidia.open = false/true` to choose between proprietary and open kernel modules
- `hardware.nvidia.prime.sync.enable = true` to switch from offload to sync mode

A consolidated local file should consist of Category C plus any deliberate Category D choices, with Categories A and B removed.

---

## 12. Runtime flexibility: `supergfxctl`

Because `shared.nix` enables `supergfxd`, you have access to `supergfxctl`:

```
supergfxctl -g                    # query current mode
supergfxctl -m Hybrid             # PRIME offload (default)
supergfxctl -m Integrated         # dGPU physically off via MUX (max battery)
supergfxctl -m Dedicated          # dGPU drives display (max performance, requires reboot)
supergfxctl -m AsusMuxDgpu        # alternate dedicated mode
supergfxctl -m Vfio               # bind dGPU to vfio for VM passthrough
```

`Integrated` is the meaningful one for battery — it does what the old "iGPU-only" BIOS option used to do, physically powering down the dGPU instead of just letting it idle. PRIME offload alone leaves the dGPU drawing 5–10W idle; Integrated mode drops that to zero.

Mode changes via `supergfxctl` happen at runtime (with a logout/login for some modes); they don't require a reboot or a NixOS specialisation. This is meaningfully different from the wiki's documented specialisation pattern and is one of the practical advantages of importing this module versus rolling your own configuration.

---

## 13. Things upstream does not solve

For completeness, the upstream module **does not** address:

- **Display refresh rate management** (forcing 60Hz on battery for power savings) — handled by your compositor or `asusctl`.
- **Per-application GPU selection** — use `nvidia-offload <cmd>` or environment variables on the specific command.
- **Suspend-resume corruption on specific kernel/driver combinations** — the module's `mem_sleep_default=deep` choice is a strong baseline, but driver bugs come and go. The wiki's troubleshooting section covers `nvidia.NVreg_TemporaryFilePath` and similar workarounds.
- **External display via dGPU** (clamshell mode) — typically requires `prime.sync.enable = true` instead of offload, since the HDMI/DP outputs on the GA402X are wired to the dGPU.
- **CUDA application setup** — outside the module's scope, see the CUDA wiki page.
- **Game-specific tuning, Wine/Proton configuration** — outside scope.

These remain your local responsibility.

---

## 14. Summary in one paragraph

The `nixos-hardware` module for the GA402X is a tree of around eight small Nix modules that compose into a complete hardware configuration for this laptop. The leaf you import (`-nvidia` or `-amdgpu`) selects the GPU configuration; both share `shared.nix` for chassis-level concerns; both transitively pull in `common/cpu/amd`, `common/gpu/amd`, and laptop/SSD common modules; the `-nvidia` leaf additionally pulls in `common/gpu/nvidia/{prime,ada-lovelace}`. The result, after evaluation, is a system with sensible defaults for AMD CPU power management, AMD iGPU support, NVIDIA dGPU with PRIME offload, the ASUS daemon stack (`asusd`, `supergfxd`), kernel parameters tuned for this chassis's suspend behavior, kernel-version-conditional keyboard workarounds, and Mediatek WiFi tweaks behind an opt-in. Settings that are non-negotiable (KMS, bus IDs, nouveau blacklist) are hardcoded; settings that represent reasonable defaults but might be overridden are `mkDefault`. The single most important thing to internalize is that `hardware.nvidia.powerManagement.enable` is left commented-out **deliberately**, because upstream tested it on this exact GPU and it causes suspend hangs — overriding that locally is overriding upstream's tested-bad finding. Beyond that, your local NVIDIA configuration should consist only of things upstream doesn't cover (CUDA cache, unfree predicate, nix-ld libraries, application services) and any deliberate deviations you've thought through.

---

## 15. References

- Module source (this audit's subject): `github.com/NixOS/nixos-hardware/tree/master/asus/zephyrus/ga402x`
- Deprecation history: PR #1046, PR #1053, issue #1052 in the nixos-hardware repo
- NVIDIA wiki page: `wiki.nixos.org/wiki/NVIDIA`
- CUDA wiki page: `wiki.nixos.org/wiki/CUDA`
- ASUS Linux project (origin of `asusd` / `supergfxd`): `asus-linux.org`
- Driver branch reference (Ada Lovelace requires ≥ 535): NVIDIA's release notes
