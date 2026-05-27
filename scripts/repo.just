import "_shared.just"

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
