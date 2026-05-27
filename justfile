import "scripts/nix.just"
import "scripts/dev.just"
import "scripts/tests.just"
import "scripts/repo.just"

# Default: list recipes
default:
    @just --list
