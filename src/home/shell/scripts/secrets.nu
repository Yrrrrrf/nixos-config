#!/usr/bin/env nu
# secrets.nu — inventory secretspec-managed secrets across GNOME Keyring and project manifests

# Password prompt for viewing unmasked secret values
def require-auth []: nothing -> nothing {
    print "Password required to view secrets:"
    sudo -k
    let result = (do { sudo -v } | complete)
    if $result.exit_code != 0 {
        error make {msg: "authentication failed, aborting"}
    }
}

# Fetch raw secret-tool search blocks for secretspec entries
def fetch-keyring-entries []: nothing -> list<record> {
    let out = (
        secret-tool search --all xdg:schema org.freedesktop.Secret.Generic
        | complete
    )
    if $out.exit_code != 0 and ($out.stdout | str trim) == "" {
        return []
    }
    
    let blocks = (
        $out.stdout
        | split row -r '(?m)^\[/\d+\]$'
        | where {|block| ($block | str trim) != '' }
    )

    $blocks | each {|block|
        let lines = ($block | lines | where {|l| $l != '' })
        let label_line = ($lines | where {|l| $l starts-with 'label ='} | get -o 0)
        let secret_line = ($lines | where {|l| $l starts-with 'secret ='} | get -o 0)
        if $label_line == null or not ($label_line =~ 'secretspec/') {
            return null
        }
        let m = (
            $label_line
            | parse -r 'secretspec/(?<store>[^/]+)/(?<profile>[^/]+)/(?<key>[^:]+):'
            | get -o 0
        )
        if $m == null {
            return null
        }
        let raw_val = (if $secret_line != null { $secret_line | str replace -r '^secret = ?' '' } else { "" })
        {
            store: $m.store,
            profile: $m.profile,
            key: $m.key,
            value: $raw_val
        }
    } | where {|row| $row != null }
}

# Scan manifests for project-to-key declarations
def scan-manifests []: nothing -> list<record> {
    let home = $env.HOME
    let lab_dir = $"($home)/Documents/lab"
    let global_manifest = $"($home)/.config/secretspec/global/secretspec.toml"
    
    mut manifest_files = []
    if ($global_manifest | path exists) {
        $manifest_files = ($manifest_files | append $global_manifest)
    }
    if ($lab_dir | path exists) {
        let found = (glob $"($lab_dir)/**/secretspec.toml")
        $manifest_files = ($manifest_files | append $found)
    }

    $manifest_files | each {|file|
        let toml = (open $file)
        let proj_name = ($toml | get -o project.name | default "unknown")
        let default_keys = ($toml | get -o profiles.default | default {} | columns)
        $default_keys | each {|k|
            { project: $proj_name, key: $k }
        }
    } | flatten
}

# Apply masking logic based on disclosure level: "none", "show", "full"
def mask-value [value: any, level: string]: nothing -> any {
    if $value == null {
        return null
    }
    let val_str = ($value | into string)
    if $val_str == "" {
        return ""
    }
    match $level {
        "none" => "••••••••",
        "show" => ($val_str | str substring 0..15),
        "full" => $val_str,
        _ => "••••••••"
    }
}

export def main [
    --show (-s)           # Show 16-character secret prefixes (requires auth)
    --show-full (-f)      # Show full secret values (requires auth)
    --export (-e)         # Export declared secrets from local secretspec.toml to .env file
]: nothing -> any {
    if $export {
        if not ("secretspec.toml" | path exists) {
            error make {msg: "No secretspec.toml found in current directory"}
        }
        let toml = (open secretspec.toml)
        let keys = ($toml | get -o profiles.default | default {} | columns)
        if ($keys | is-empty) {
            print "No secrets declared in profiles.default"
            return
        }
        let env_content = ($keys | each {|k| $"($k)=(secretspec get $k)" } | str join "\n")
        $"($env_content)\n" | save -f .env
        print $"✓ Exported ($keys | length) secrets to .env"
        return
    }

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
