# Secretspec Reference & Usage Manual (`SECRETSPEC.md`)

This guide provides a comprehensive reference for using `secretspec` (v0.10+) on this machine, covering manifest syntax, CLI commands, provider aliases, process-scoped execution, and best practices.

---

## 1. Core Mental Model

`secretspec` decouples **secret declarations** from **secret storage**:

1. **Declarative Manifests (`secretspec.toml`):** Repositories declare *which* environment variables they require, whether they are required or optional, and which provider backend resolves them.
2. **Process-Scoped Injection (`secretspec run`):** `secretspec` injects secrets directly into child process environment variables. The parent interactive shell never holds raw secrets in its environment.
3. **User-Scoped Provider Routing (`~/.config/secretspec/config.toml`):** Global user configuration defines default providers and named provider aliases (e.g. `shared`).

---

## 2. Configuration & Manifest Specification

### Global User Config (`~/.config/secretspec/config.toml`)

Defines default provider settings and global provider aliases:

```toml
[defaults]
provider = "keyring"
profile = "development"

[defaults.providers]
shared = "keyring://secretspec/shared/{profile}/{key}"
```

* `provider`: Default backend (e.g. `keyring`, `dotenv`, `onepassword`).
* `profile`: Active profile (default: `development`).
* `providers.<alias>`: Named indirection routing logical store names to physical URI templates.

---

### Project Manifest (`secretspec.toml`)

Placed in project roots or referenced via `--file`:

```toml
[project]
name = "azathoth"
revision = "1.0"

[profiles.default]
# Cross-cutting API key resolving via the user 'shared' alias
GEMINI_API_KEY = { description = "Gemini API key", required = true, providers = ["shared"] }

# Project-scoped secret resolving via default provider (keyring://secretspec/azathoth/development/PYPI_TOKEN)
PYPI_TOKEN = { description = "PyPI deployment token", required = true }

[profiles.development]
```

#### Field Specifications:
* `description` *(string)*: Human-readable explanation of the secret.
* `required` *(bool)*: If `true`, `secretspec run` or `secretspec check` fails if the secret is missing from the provider. If `false`, missing secrets are skipped without blocking execution.
* `providers` *(list of strings)*: List of provider alias names or URIs to resolve the secret from.

---

## 3. CLI Command Reference

### `secretspec run` — Inject Secrets into a Command

Spawns a child process with declared secrets populated as environment variables:

```bash
# Run command using auto-detected secretspec.toml in current/parent directory
secretspec run -- cargo test

# Run command using a specific manifest file
secretspec run --file ~/.config/secretspec/global/secretspec.toml -- uvx azathoth workflow commit

# Override active profile for this invocation
secretspec run --profile production -- python deploy.py
```

---

### `secretspec set` — Store a Secret Value

Writes a secret value into the provider backend:

```bash
# Set a secret interactively (prompts for value)
secretspec set GEMINI_API_KEY

# Set a secret with value passed directly
secretspec set GEMINI_API_KEY "my-secret-key-value"

# Set a shared secret using a specific manifest target
secretspec set --file ~/.config/secretspec/global/secretspec.toml GEMINI_API_KEY "my-shared-key"
```

---

### `secretspec get` — Retrieve a Secret Value

Prints the value of a secret from the provider:

```bash
# Get secret using auto-detected manifest
secretspec get GEMINI_API_KEY

# Get secret from a specific manifest
secretspec get --file ~/.config/secretspec/global/secretspec.toml GEMINI_API_KEY
```

---

### `secretspec check` — Validate Secret Resolution

Verifies that all required secrets declared in the manifest exist in the underlying provider:

```bash
# Check current project manifest
secretspec check

# Check specific manifest file
secretspec check --file ~/Documents/lab/ai/secretspec.toml
```

Example Output:
```
Checking secrets in azathoth (profile: development)...

✓ GEMINI_API_KEY - Gemini API key
✓ PYPI_TOKEN - PyPI deployment token

Summary: 2 found, 0 missing
```

---

### `secretspec config` — Manage Configuration & Aliases

Manages global user settings and provider aliases in `~/.config/secretspec/config.toml`:

```bash
# View active global configuration and provider aliases
secretspec config provider list

# Add or update a provider alias
secretspec config provider add shared "keyring://secretspec/shared/{profile}/{key}"

# Remove a provider alias
secretspec config provider remove shared
```

---

## 4. Machine Workflows & Best Practices

1. **Use Process-Scoped Injection (`secretspec run`):**
   * Never export API keys in `env.nu` or `.bashrc`.
   * Use wrappers like `commit` or `secretspec run` to keep the shell environment clean.

2. **Cross-Cutting vs Project-Scoped Secrets:**
   * **Shared Secrets:** Add `providers = ["shared"]` in manifest declarations so one keyring entry handles all consumers.
   * **Project-Scoped Secrets:** Omit `providers` so keys remain scoped to `secretspec/{project}/{profile}/{key}`.

3. **Keep Manifests Self-Contained:**
   * Avoid `extends`. Explicitly declare all keys in each `secretspec.toml` to ensure every repository works in isolation.

---

## 5. Quick Command Cheat Sheet

| Action | Command |
| ------ | ------- |
| **Run command with secrets** | `secretspec run -- <cmd>` |
| **Run with explicit manifest** | `secretspec run --file <path> -- <cmd>` |
| **Set secret value** | `secretspec set <KEY> [<VALUE>]` |
| **Get secret value** | `secretspec get <KEY>` |
| **Validate manifest secrets** | `secretspec check` |
| **List provider aliases** | `secretspec config provider list` |
| **Add provider alias** | `secretspec config provider add <alias> <URI>` |
