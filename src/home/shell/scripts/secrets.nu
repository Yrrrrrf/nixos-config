#!/usr/bin/env nu
# secrets.nu — inventory secretspec-managed secrets across GNOME Keyring and project manifests
use _secrets.nu *

export def main [
    --show (-s)           # Show 16-character secret prefixes (requires auth)
    --show-full (-f)      # Show full secret values (requires auth)
]: nothing -> table {
    let level = if $show_full {
        "full"
    } else if $show {
        "show"
    } else {
        "none"
    }

    if $level != "none" {
        require-auth
    }

    let keyring = (fetch-keyring-entries)
    let manifests = (scan-manifests)

    # Group keyring entries by key and value to deduplicate identical values across stores,
    # while preserving separate rows if a key has divergent values.
    let keyring_groups = ($keyring | select key value | uniq)

    mut combined = []

    for g in $keyring_groups {
        let matching_entries = ($keyring | where key == $g.key and value == $g.value)
        let stores = ($matching_entries | get store | uniq | sort)
        let stored_str = ($stores | str join ", ")
        
        let matching_projs = ($manifests | where key == $g.key | get project | uniq | sort)

        $combined = ($combined | append {
            key: $g.key,
            value: (mask-value $g.value $level),
            stored: $stored_str,
            projects: $matching_projs
        })
    }

    # Find keys in manifests not present in keyring
    let missing_keys = ($manifests | where {|m| not ($keyring_groups | any {|g| $g.key == $m.key }) } | select key | uniq)
    for m in $missing_keys {
        let matching_projs = ($manifests | where key == $m.key | get project | uniq | sort)
        $combined = ($combined | append {
            key: $m.key,
            value: null,
            stored: null,
            projects: $matching_projs
        })
    }

    let sorted = ($combined | sort-by key)

    if $level != "none" {
        $sorted | select key value
    } else {
        $sorted
    }
}
