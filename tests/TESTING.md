# Chimera UI Testing Methodology

This document codifies the pattern for hardening and benchmarking UI-facing scripts. Every test in this directory must strive for **maximum signal, minimum boilerplate**.

## 1. Core Philosophy: "Assert-and-Pass"

We avoid "Framework Bloat." Nu is a powerful shell; we use its native strengths instead of building a custom test runner.

- **No Result Records**: Tests do NOT return lists of `{name, passed}` records. They execute directly.
- **Fail Fast**: Use `use std assert`. If a hardware state change fails, the test should halt immediately with a clear error.
- **Visual Verification**: Every test must include a delay (`sleep`) between actions so the human can verify the OSD/Notification feedback.
- **State Integrity**: Always capture the original state first and use a `try { ... } finally { ... }` pattern to ensure the system is restored even if a test fails.

## 2. Script Hardening (Source of Truth)

Scripts in `src/` are the ground truth. Hardening means:

- **Hardware-First**: Use `wpctl`, `brightnessctl`, `asusctl` for the work.
- **Visual-Mandatory**: Every mutation must trigger `swayosd-client`.
- **Granular Feedback**: For continuous values, use **Sweeps** (0% -> 100% -> 0%). For discrete values, use **Full Rotations**.

## 3. The `_lib.nu` Standard

The library should provide only the essentials:

- `snap`: Snapshot the current script state.
- `act`: Execute an action on a script.
- `audit`: A clean, colored header for grouping related logic.
- `pass`: A simple green-check formatter for successful steps.

### Example of the Ideal Test:

```nu
use _lib.nu *
use std assert

audit "Example Component" {
    let original = (snap $script)
    
    try {
        act $script "--change"
        sleep 1sec
        let now = (snap $script)
        
        assert ($now != $original) "State did not change"
        pass "State toggle verified"
    } finally {
        act $script "--set" $original
    }
}
```

## 4. Execution Patterns

- **`just health`**: Validates JSON contracts and service status. Low-noise, run-once.
- **`just bench-ui <feature>`**: Interactive lifecycle validation. High-signal, visual feedback.
- **`just bench-ui all`**: Full system suite. Runs every component in sequence.

## 5. Refactoring Goals

- [ ] Eliminate `orchestrate` and its complex list-tracking.
- [ ] Replace manual ANSI codes with Nu's native styling (e.g., `(print -e $"(ansi green)✓(ansi reset)")`).
- [ ] Consolidate `check_exec` / `check_grep` into simple `assert` calls.
- [ ] Move toward `std log` for standardized logging levels.
