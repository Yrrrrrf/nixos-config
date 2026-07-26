#!/usr/bin/env nu
# commit — stage all changes and run AI commit with global secretspec manifest
export def main [...args: string]: nothing -> any {
    git add -A
    secretspec run --file $"($env.HOME)/.config/secretspec/global/secretspec.toml" -- uvx azathoth workflow commit ...$args
}
