import "scripts/nix.just"
import "scripts/dev.just"
import "scripts/repo.just"

# Default: list recipes
default:
    @just --list
