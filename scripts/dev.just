import "_shared.just"

user := env('USER')
group := "users"
dir := justfile_directory()

[doc("Format all files")]
[group("CI")]
fmt:
    alejandra . o+e>| head -n 1

[doc("Check the configuration for errors")]
[group("CI")]
check: fmt
    nix flake check
    flake-checker

[doc("Lint (statix) + dead-code (deadnix)")]
[group("CI")]
lint:
    statix check .
    deadnix --fail .

[group("CI")]
quality: fmt check lint

[doc("Check GPU status")]
[group("AI")]
check-gpu:
    cd ~/docs/lab/ai; uv run scripts/check_gpu.py

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

[doc("Show ownership of all files (highlights anything not owned by you)")]
[group("Permissions")]
status:
    @echo "Repo: {{ dir }}"
    @echo "Files NOT owned by {{ user }}:"
    @fd . {{ dir }} --type f --hidden --exclude .git \
        -x stat -c '%U:%G %a %n' {} \; \
        | rg -v "^{{ user }}:" || echo "  ✓ all clean"
