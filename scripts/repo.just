import "_shared.just"

[doc("Format all files")]
[group("CI")]
fmt:
    alejandra .

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
