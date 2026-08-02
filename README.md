# NixOS Dendritic Configuration

This repository contains a modular, dendritic NixOS configuration optimized for
the ASUS Zephyrus G14 (2022/2024) and focused on developer productivity and rich
aesthetics.

## Architecture: Dendritic Pattern

The codebase follows the "Dendritic" architecture, where every file in the
`src/` directory is a self-contained `flake-parts` module. This eliminates the
need for manual `imports = [ ... ]` chains and allows for granular, toggleable
aspects.

### Structure

- `src/home/`: Home Manager aspects (Shell, Desktop, Editor, Scripts).
- `src/host/`: Machine-specific configurations (currently `g14`).
- `src/profiles/`: Profile compositions (`default`, `dev`, `minimal`) and their
  associated NixOS specialisations.
- `src/system/`: System-wide NixOS modules (Networking, Services, Nvidia/CUDA,
  etc.).
- `src/users/`: User-specific declarations.
- `scripts/`: Custom shell scripts symlinked into the environment.

### The `_` Prefix Convention

Any path containing a segment starting with `_` (e.g. `_hardware-configuration.nix`)
is skipped by `import-tree`'s default filter. The same prefix is used inside
`src/home/shell/scripts.nix` and `src/home/desktop/desktop.nix` to mark a `.nu`
file as a library rather than an installable command (e.g. `_shared.nu`, consumed
via `use _shared.nu *`): kept as-is, not stripped of its suffix, not made
executable.

## Key Features

- **Machine-Wide Secrets:** machine-wide secret management, the `shared`
  provider alias, and the `secrets` & `commit` commands are documented locally
  under `docs/` (gitignored, not part of this repo's history).
- **Secretspec Reference:** a comprehensive CLI and manifest usage guide for
  `secretspec` lives locally at `docs/SECRETSPEC.md` (gitignored).
- **Specialisations:** `dev` and `minimal` boot specialisations exist in the
  codebase but are currently disabled in `src/host/g14/g14.nix`.
- **Dendritic Registry:** All aspects are exposed via `inputs.self.homeModules`
  and `inputs.self.nixosModules`.
- **Advanced CLI Tools:** Includes `direnv`, `nix-index`, `difftastic`, `nh`,
  `atuin`, and more.
- **Hyprland Desktop:** A fully configured Wayland environment with `waybar`,
  `walker`, and `dunst`.

## Management

Use the provided `justfile` for common tasks:

- `just check`: Evaluate and lint the flake.
- `just fmt`: Format all Nix files using `alejandra`.
- `just build`: Build the system configuration.
- `just switch`: Build and switch to the new configuration.
