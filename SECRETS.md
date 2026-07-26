# Machine-Wide Secrets Architecture & Guide

This document describes the machine-wide secret management system built on
`secretspec` and GNOME Keyring.

---

## 1. Architecture Overview

Secrets are organized into three decoupled planes:

```
CONSUMERS          commit              secretspec run          secrets
                  (any repo)          (inside a project)     (inventory)
                       │                      │              │       │
                       ▼                      ▼              │       │
DECLARATION     global manifest      project manifest ───────┘       │
                ~/.config/           ~/Documents/lab/*/         (reads all
                secretspec/global/    secretspec.toml            manifests)
                       │                      │                      │
                       └──────── providers = ["shared"] ─────┐       │
                                                              ▼       │
ROUTING                          alias  shared = keyring://secretspec/shared/{profile}/{key}
                                        ~/.config/secretspec/config.toml
                                                              │       │
                                                              ▼       ▼
STORAGE                          GNOME Keyring — one entry per key
                                 secretspec/shared/development/GEMINI_API_KEY
                                 secretspec/azathoth/development/PYPI_TOKEN
```

- **Storage Plane:** GNOME Keyring (Secret Service). Stores cross-cutting API
  keys under `secretspec/shared/development/{KEY}` (one entry per key across the
  entire machine).
- **Routing Plane:** Managed via `~/.config/secretspec/config.toml` using the
  `shared` provider alias (`keyring://secretspec/shared/{profile}/{key}`).
- **Declaration Plane:** Project manifests (`~/Documents/lab/*/secretspec.toml`)
  and the global manifest (`~/.config/secretspec/global/secretspec.toml`).
- **Consumption Plane:** Shell wrappers `secrets` and `commit` in
  `~/.local/bin/`.

---

## 2. Where Things Live

| File / Location                               | Ownership / Purpose                                                                                       |
| --------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `~/.config/secretspec/config.toml`            | Global user configuration and provider aliases (defines `shared`).                                        |
| `~/.config/secretspec/global/secretspec.toml` | Global manifest declaring cross-cutting API keys (`GEMINI_API_KEY`, `OPENAI_API_KEY`, etc.).              |
| `~/Documents/lab/*/secretspec.toml`           | Project manifests declaring project requirements.                                                         |
| `~/.local/bin/secrets`                        | CLI script for inventory, inspection, and verification across manifests and keyring.                      |
| `~/.local/bin/commit`                         | CLI wrapper that injects `GEMINI_API_KEY` from the global manifest to run AI commit messages in any repo. |

---

## 3. How to Use the Commands

### `secrets` — Inventory & Inspection

Run `secrets` from any directory to see the status of all secrets declared in
project manifests or stored in the keyring:

```bash
# View table with all secret values fully masked (no password prompt required)
secrets

# Show 16-character secret prefixes (prompts for password via PAM)
secrets --show          # or -s

# Show complete secret values (prompts for password via PAM)
secrets --show-full     # or -f
```

Example Output:

```
───┬───────────────────┬──────────┬──────────┬───────────────────────────
 # │ key               │ value    │ stored   │ projects                  
───┼───────────────────┼──────────┼──────────┼───────────────────────────
 0 │ ANTHROPIC_API_KEY │ •••••••• │ shared   │ [ai, global]              
 1 │ DEEPSEEK_API_KEY  │ •••••••• │ shared   │ [ai, global]              
 2 │ GEMINI_API_KEY    │ •••••••• │ shared   │ [ai, azathoth, global]    
 3 │ MINIMAX_API_KEY   │ •••••••• │ shared   │ [ai, global]              
 4 │ MOONSHOT_API_KEY  │ •••••••• │ shared   │ [ai, global]              
 5 │ OPENAI_API_KEY    │ •••••••• │ shared   │ [ai, global]              
 6 │ PYPI_TOKEN        │ •••••••• │ azathoth │ [azathoth]                
───┴───────────────────┴──────────┴──────────┴───────────────────────────
```

### `commit` — AI Commit Message Generator

Run `commit` from any Git repository (even repos with no `.env` or local
`secretspec.toml`):

```bash
# Stage all changes and generate commit message interactively
commit

# Auto-accept generated commit message without prompt
commit -y

# Pass focus hints to the generator
commit -f "Refactor error handling"
```

---

## 4. How to Add a Secret

1. **Classify the secret:**
   - **Shared API Key:** (e.g. `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`) used
     across multiple projects or tools.
   - **Project-Scoped Token:** (e.g. `PYPI_TOKEN`) tied to a single repository.

2. **Add to Manifest:**
   - For **shared keys**, add to `~/.config/secretspec/global/secretspec.toml`
     and your project's `secretspec.toml` with `providers = ["shared"]`:
     ```toml
     GEMINI_API_KEY = { description = "Gemini API key", required = true, providers = ["shared"] }
     ```
   - For **project-scoped keys**, add to the project's `secretspec.toml` without
     `providers`:
     ```toml
     PYPI_TOKEN = { description = "PyPI upload token", required = true }
     ```

3. **Store in Keyring:**
   - For shared keys:
     ```bash
     secretspec set --file ~/.config/secretspec/global/secretspec.toml GEMINI_API_KEY
     ```
   - For project keys:
     ```bash
     secretspec set PYPI_TOKEN
     ```

---

## 5. How to Rotate a Secret

Because shared API keys are deduplicated under
`secretspec/shared/development/{KEY}`, you only need to rotate a shared key
**once**:

```bash
secretspec set --file ~/.config/secretspec/global/secretspec.toml GEMINI_API_KEY "new-key-value"
```

This single command instantly updates the key for `ai`, `azathoth`, `commit`,
and any other consumer on the machine.

---

## 6. How to Add a New Project

1. Create a `secretspec.toml` in your project root:
   ```toml
   [project]
   name = "my-new-project"
   revision = "1.0"

   [profiles.default]
   GEMINI_API_KEY = { description = "Gemini API key", required = true, providers = ["shared"] }
   MY_PROJECT_KEY = { description = "Local project secret", required = true }

   [profiles.development]
   ```
2. Keep manifests **self-contained** (never use `extends`).
3. Run `secretspec check` to verify resolution.

---

## 7. Operational Traps & Safeguards

- **Never export `SECRETSPEC_FILE` globally:** Keep manifest selection scoped to
  individual invocations (`--file`). Exporting `SECRETSPEC_FILE` globally
  corrupts project auto-detection.
- **Auth Gate Notice:** The password prompt in `secrets --show` is a
  shoulder-surfing safeguard, not an encryption boundary.
- **Divergent Values:** If `secrets` shows two rows for the same key name, two
  distinct values exist in the keyring (key drift).
- **Deleting Secrets:** `secretspec` has no `delete` subcommand. Use
  `secret-tool clear` with exact attributes if an entry must be removed from
  Secret Service.

---

## 8. Health Verification

Run this check periodically to ensure secret integrity:

```bash
# 1. Verify inventory
secrets

# 2. Verify global commit command from /tmp
cd /tmp && commit --dry-run

# 3. Check project resolution
secretspec check --file ~/Documents/lab/ai/secretspec.toml
```
