# NixOS config — permission & rebuild helpers
# Run `just` to see all recipes.

set shell := ["bash", "-cu"]

user := env('USER')
group := "users"
dir := justfile_directory()

# Default: list recipes
default:
    @just --list

# === Permissions ===========================================================

[doc("Show ownership of all files (highlights anything not owned by you)")]
[group("Permissions")]
status:
    @echo "Repo: {{ dir }}"
    @echo "Files NOT owned by {{ user }}:"
    @fd . {{ dir }} --type f --hidden --exclude .git \
        -x stat -c '%U:%G %a %n' {} \; \
        | rg -v "^{{ user }}:" || echo "  ✓ all clean"

[doc("Unlock: take ownership so you can edit without sudo")]
[group("Permissions")]
unlock:
    @echo "→ chown {{ user }}:{{ group }} on {{ dir }}"
    sudo chown -R {{ user }}:{{ group }} {{ dir }}
    @echo "✓ unlocked — edit freely"

[doc("Lock: hand ownership back to root (read-only for you)")]
[group("Permissions")]
lock:
    @echo "→ chown root:root on {{ dir }}"
    sudo chown -R root:root {{ dir }}
    @echo "✓ locked"

[doc("Normalize file modes: 644 for files, 755 for dirs, +x on scripts")]
[group("Permissions")]
fix-modes:
    sudo find {{ dir }} -path '*/.git' -prune -o -type d -exec chmod 755 {} +
    sudo find {{ dir }} -path '*/.git' -prune -o -type f -exec chmod 644 {} +
    sudo find {{ dir }}/home/scripts -type f -name '*.sh' -exec chmod 755 {} +
    @echo "✓ modes normalized"

[doc("Full reset: unlock + fix modes")]
[group("Permissions")]
reset: unlock fix-modes
    @just status

# === NixOS ===============================================================

[doc("Build only — no activation")]
[group("NixOS")]
build:
    nh os build

[doc("Rebuild and switch")]
[group("NixOS")]
switch:
    nh os switch

[doc("Update flake inputs and switch")]
[group("NixOS")]
update:
    nh os switch --update

[doc("Garbage collect old generations (keeps last 7 days)")]
[group("NixOS")]
clean:
    nh clean all

# === CI ====================================================================

[doc("Check the configuration for errors")]
[group("CI")]
check: fmt
    nix flake check
    alejandra --check .

[doc("Format all files")]
[group("CI")]
fmt:
    alejandra .

[doc("Show the largest files in git history")]
[group("git")]
git-bloat:
    @git rev-list --objects --all \
      | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
      | rg '^blob' | sort -k3 -n -r | head -20

[doc("Repo size")]
[group("git")]
git-size:
    @du -sh .git
    @echo "Working tree:"
    @du -sh --exclude=.git .

[working-directory("/home/yrrrrrf/docs/lab/ai")]
check-gpu:
    uv run scripts/check_gpu.py
