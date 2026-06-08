# home/shell/fn.nu
# Convert any file to .txt (same name, new extension)
def to-txt [file: path] {
    let out = (
        $file | path parse | update extension "txt" | path join | path expand
    )
    open --raw $file | save -f $out
    print $"📄 ($file) → ($out)"
}

# Load a .env file into the current environment
def --env dotenv [file: path = .env] {
    let record = (
        open --raw $file | lines | where {|l|
            let t = ($l | str trim)
            $t != '' and not ($t | str starts-with '#')
          } | parse "{key}={val}" | reduce -f {} {|row, acc| $acc | upsert $row.key $row.val}
    )
    load-env $record
    let keys = ($record | columns)
    print $"🔑 Loaded ($keys | length) keys from ($file | path expand):"
    $keys | each {|k| print $"   • ($k)"}
    null
}

# Open in hx the result of fd
def fhx [pattern: string]: nothing -> nothing {
    let matches = fd $pattern | lines
    match ($matches | length) {
        0 => null                      # nothing found → no-op
        1 => { hx ($matches | first) } # single hit → open it
        _ => {
            # multiple → fuzzy-pick one
            let pick = $matches | str join (char newline) | sk | str trim
            if ($pick | is-not-empty) { hx $pick }
        }
    }
}
