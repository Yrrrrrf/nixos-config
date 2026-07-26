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

    # Gather all unique (key, value, store) combinations from keyring
    # plus keys declared in manifests that are missing from keyring.
    let keyring_keys = ($keyring | select key value store | uniq)

    mut combined = []

    for k in $keyring_keys {
        let matching_projs = ($manifests | where key == $k.key | get project | uniq | sort)
        $combined = ($combined | append {
            key: $k.key,
            value: (mask-value $k.value $level),
            stored: $k.store,
            projects: $matching_projs
        })
    }

    # Find keys in manifests not present in keyring
    let missing_keys = ($manifests | where {|m| not ($keyring_keys | any {|k| $k.key == $m.key }) } | select key | uniq)
    for m in $missing_keys {
        let matching_projs = ($manifests | where key == $m.key | get project | uniq | sort)
        $combined = ($combined | append {
            key: $m.key,
            value: null,
            stored: null,
            projects: $matching_projs
        })
    }

    $combined | sort-by key
}
