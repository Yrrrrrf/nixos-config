**Implementation Plan: Desktop Module Overhaul**

---

**Phase 1 — Stylix**
- Add `stylix` to `flake.nix` inputs
- Create `theme.nix` with base16 Catppuccin Mocha scheme + `_module.args.theme`

---

**Phase 2 — Native Config Files**

Add `@placeholders@` where theme colors appear:
- `hyprland.conf` → border colors, inactive colors
- `hyprlock.conf` → background, text colors
- `waybar-style.css` → all color references
- `rofi.rasi` → all color references
- `dunst.conf` → new file (extract from `dunst.nix`)
- `hypridle.conf` → new file (extract from `hypridle.nix`)
- `wezterm.lua` → new file (extract from `wezterm.nix`)
- `waybar.jsonc` → new file (extract from `waybar.nix`)

---

**Phase 3 — `desktop.nix`**

Single file that:
- Imports `theme.nix`
- Enables all services/programs
- Injects theme into native files via `readFile + replaceStrings`
- Contains the `home.file` scripts block (moved from `common.nix`)

---

**Phase 4 — Cleanup**
- Delete `dunst.nix`, `hypridle.nix`, `hyprland.nix`, `hyprlock.nix`, `rofi.nix`, `waybar.nix`, `wezterm.nix`, `swayosd.nix`
- Update top-level imports to just `desktop` + `shell`
- Remove scripts block from `common.nix`
- Remove dead `fn.sh` comment from `zsh.nix`

---

**Phase 5 — Test**
- `nixos-rebuild switch`
- Verify each program launches and themes correctly
- Verify scripts work from Hyprland keybinds

---

**Order matters:** Phase 1 → 2 → 3 → 4 → 5. Don't delete old files until `desktop.nix` builds successfully.

Ready to start Phase 1?
