# NixOS Dendritic Configuration

This repository contains a modular, dendritic NixOS configuration optimized for the ASUS Zephyrus G14 (2022/2024) and focused on developer productivity and rich aesthetics.

## Architecture: Dendritic Pattern

The codebase follows the "Dendritic" architecture, where every file in the `src/` directory is a self-contained `flake-parts` module. This eliminates the need for manual `imports = [ ... ]` chains and allows for granular, toggleable aspects.

### Structure

- `src/home/`: Home Manager aspects (Shell, Desktop, Editor, Scripts).
- `src/host/`: Machine-specific configurations (currently `g14`).
- `src/profiles/`: Profile compositions (`default`, `dev`, `minimal`) and their associated NixOS specialisations.
- `src/system/`: System-wide NixOS modules (Networking, Services, Nvidia/CUDA, etc.).
- `src/users/`: User-specific declarations.
- `scripts/`: Custom shell scripts symlinked into the environment.

## Key Features

- **Specialisations:** Toggle between `dev` and `minimal` environments at boot or runtime.
- **Dendritic Registry:** All aspects are exposed via `inputs.self.homeModules` and `inputs.self.nixosModules`.
- **Advanced CLI Tools:** Includes `direnv`, `nix-index`, `difftastic`, `nh`, `atuin`, and more.
- **Hyprland Desktop:** A fully configured Wayland environment with `waybar`, `rofi`, and `dunst`.
- **Hardened Database:** Includes RLS policies and spatial integrity checks for geospatial workloads.

## Management

Use the provided `justfile` for common tasks:

- `just check`: Evaluate and lint the flake.
- `just fmt`: Format all Nix files using `alejandra`.
- `just build`: Build the system configuration.
- `just switch`: Build and switch to the new configuration.

## Specialisations

To switch to a specialisation at runtime:
```bash
sudo /run/current-system/specialisation/dev/bin/switch-to-configuration switch
```
