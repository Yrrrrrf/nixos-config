# Classic → Modern Tool Replacements

> Status tags: `done` · `c-based` · `dup` · `nice-to-have`

| Classic (C/legacy) | Modern (Rust) | Command | Status | Notes |
|---|---|:---:|---|---|
| `grep` | `ripgrep` | `rg` | `done` | In `cli.nix` replacements |
| `ls` | `eza` | `eza` | `done` | In `cli.nix` replacements |
| `cat` | `bat` | `bat` | `done` | In `cli.nix` replacements |
| `find` | `fd` | `fd` | `done` | In `cli.nix` replacements |
| `cd` | `zoxide` | `z` | `done` | Via `programs.zoxide` in `zsh.nix` |
| `curl` / `httpie` | `xh` | `xh` | `c-based` `nice-to-have` | Sane HTTP client, curl-compatible flags |
| `du` | `dust` | `dust` | `c-based` `nice-to-have` | Visual disk usage tree |
| `ps` | `procs` | `procs` | `c-based` `nice-to-have` | Process viewer with tree & colors |
| `diff` (git) | `delta` | `delta` | `c-based` `nice-to-have` | Syntax-highlighted git diffs, pairs with lazygit |
| `tar` / `zip` / `unzip` | `ouch` | `ouch` | `c-based` `nice-to-have` | Unified compress/decompress, forget tar flags forever |
| `time` | `hyperfine` | `hyperfine` | `c-based` `nice-to-have` | CLI benchmarking, statistical output |
| `cloc` / `wc` | `tokei` | `tokei` | `c-based` `nice-to-have` | Code stats per language across a project |
| `nethogs` | `bandwhich` | `bandwhich` | `c-based` `nice-to-have` | Real-time network usage per process |
| `sed` | `sd` | `sd` | `c-based` `nice-to-have` | Simpler regex syntax than sed |
| `hexdump` | `hexyl` | `hexyl` | `c-based` `nice-to-have` | Colorized hex viewer |
| `man` | `tealdeer` | `tldr` | `c-based` `nice-to-have` | Practical examples instead of walls of text |
| `jq` | `jaq` | `jaq` | `c-based` `dup` `nice-to-have` | Have `jq` in `buildTools` — `jaq` is the Rust port, drop `jq` after |
| `neofetch` | `fastfetch` | `fastfetch` | `dup` | Both in config! Drop `neofetch` from `cli.nix` |
| `tree` | `eza --tree` | `eza --tree` | `done` `dup` | Have both — `tree` is redundant, `eza` already covers it |
| `fzf` | `skim` | `sk` | `done` `nice-to-have` | `fzf` is Go, `skim` is the Rust port — API-compatible drop-in |
