# Helix Language Support — Your Config

> Cross-reference of `languages.toml` vs helix capabilities vs installed Nix packages.
> LSP Status: ✅ pkg in `helix.nix` · ❌ configured but pkg missing · ⚠️ available via other means

| Language | Syntax | Treesitter | Auto Indent | Configured LSP(s) | LSP Status |
|---|:---:|:---:|:---:|---|---|
| `rust` | ✓ | ✓ | ✓ | `rust-analyzer` | ⚠️ via `rustup component add rust-analyzer`, not a nix pkg |
| `python` | ✓ | ✓ | ✓ | `pyright`, `ruff-lsp` | ✅ `pyright` · ❌ `ruff-lsp` not in `helix.nix` |
| `c` | ✓ | ✓ | ✓ | `clangd` | ❌ not in `helix.nix` — add `clang-tools` |
| `cpp` | ✓ | ✓ | ✓ | `clangd` | ❌ not in `helix.nix` — same as above |
| `typescript` | ✓ | ✓ | ✓ | `typescript-language-server` | ✅ |
| `javascript` | ✓ | ✓ | ✓ | `typescript-language-server` | ✅ |
| `json` | ✓ | ✓ | ✓ | `vscode-json-language-server` | ✅ via `vscode-langservers-extracted` |
| `html` | ✓ | — | — | `vscode-html-language-server` | ✅ via `vscode-langservers-extracted` |
| `css` | ✓ | — | ✓ | `vscode-css-language-server` | ✅ via `vscode-langservers-extracted` |
| `svelte` | ✓ | — | ✓ | `svelteserver` | ✅ `svelte-language-server` |
| `toml` | ✓ | ✓ | — | `taplo` | ✅ |
| `nix` | ✓ | ✓ | ✓ | `nil` | ✅ |
| `sql` | ✓ | ✓ | — | `sqls` | ✅ |
| `bash` | ✓ | ✓ | ✓ | `bash-language-server` | ✅ |
| `go` | ✓ | ✓ | ✓ | `gopls` | ✅ |
| `asm` (gas/nasm) | ✓ | ✓ | — | `asm-lsp` | ✅ |
| `kotlin` | ✓ | ✓ | ✓ | `kotlin-language-server` | ✅ |
| `hyprlang` | ✓ | — | ✓ | `hyprls` | ✅ |
| `typst` | ✓ | — | — | `tinymist` | ✅ |
| `just` | ✓ | ✓ | ✓ | `just-lsp` | ❌ not yet added to `helix.nix` |

## Action Items

| Fix | What to do |
|---|---|
| `ruff-lsp` missing | Add `ruff` to `helix.nix` packages |
| `clangd` missing | Add `clang-tools` to `helix.nix` packages |
| `rust-analyzer` unmanaged | Either accept rustup-managed or add `rust-analyzer` to `helix.nix` for full nix reproducibility |
| `just-lsp` missing | Add `just-lsp` to `helix.nix` packages (discussed earlier!) |

## Additional considerations

Looking back across everything I've seen in both config files, yes — a few things stand out:

**Bug in `languages.toml` (typst)**

```toml
[[language]]
name = "typst"
language-servers = ["tinymist"]

[language-server.tinymist]
command = "tinymist"
file-types = ["typ"]   # ← this is INSIDE the LSP block, not [[language]]
```
`file-types` belongs in `[[language]]`, not `[language-server.*]`. Helix silently ignores it there, so `.typ` files won't be detected — tinymist never activates.

---

**`asm` language name doesn't exist in Helix**

Helix has `gas` (`.s` files) and `nasm` (`.asm` files), not `asm`. Your config uses `name = "asm"` which matches nothing, so `asm-lsp` never loads. You probably want:

```toml
[[language]]
name = "gas"
...
```

---

**`ruff-lsp` is deprecated**

The `ruff-lsp` package was sunset. The built-in LSP is now just `ruff server`. Fix:

```toml
[language-server.ruff-lsp]
command = "ruff"
args = ["server"]
```

And add `ruff` (not `ruff-lsp`) to `helix.nix`.

---

**`hyprlang` matches ALL `.conf` files**

```toml
file-types = ["conf"]
```
This triggers `hyprls` on *any* `.conf` file on your system (nginx, alsa, whatever). Scope it down:

```toml
file-types = [{ glob = "hypr/*.conf" }, { glob = "hyprland.conf" }]
```

---

**`nixpkgs-fmt` + `nixfmt` both in `helix.nix`**

They do the same job. `nixpkgs-fmt` is the older one being phased out — your `nix` language already uses `nixpkgs-fmt` as the formatter command, but `nixfmt` is the current standard. Pick one and drop the other.

---

Those first three are actual silent failures — your LSPs aren't loading for typst, asm, and the ruff formatter. Worth fixing first.
