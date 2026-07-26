# _secrets.nu — helper functions for keyring reads, manifest scanning, and secret masking

# Password prompt for viewing unmasked secret values
export def require-auth []: nothing -> nothing {
    print "Password required to view secrets:"
    sudo -k
    let result = (do { sudo -v } | complete)
    if $result.exit_code != 0 {
        error make {msg: "authentication failed, aborting"}
    }
}

# Fetch raw secret-tool search blocks for secretspec entries
export def fetch-keyring-entries []: nothing -> list<record> {
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
export def scan-manifests []: nothing -> list<record> {
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
export def mask-value [value: any, level: string]: nothing -> any {
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
