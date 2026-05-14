import "_shared.just"

[doc("Check the configuration for errors")]
[group("CI")]
check: fmt
    nix flake check

[doc("Check GPU status")]
[group("AI")]
check-gpu:
    cd /home/yrrrrrf/docs/lab/ai && uv run scripts/check_gpu.py

[doc("Show ownership of all files (highlights anything not owned by you)")]
[group("Permissions")]
status:
    @echo "Repo: {{ dir }}"
    @echo "Files NOT owned by {{ user }}:"
    @fd . {{ dir }} --type f --hidden --exclude .git \
        -x stat -c '%U:%G %a %n' {} \; \
        | rg -v "^{{ user }}:" || echo "  ✓ all clean"
