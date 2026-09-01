# home/shell/fn.nu
# Convert any file to .txt (same name, new extension)
def to-txt [file: path]: nothing -> nothing {
    let out = (
        $file | path parse | update extension "txt" | path join | path expand
    )
    open --raw $file | save -f $out
    print $"📄 ($file) → ($out)"
}
# Load a .env file into the current environment
def --env dotenv [file: path = .env]: nothing -> nothing {
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
# Fuzzy-pick a candidate from a list and execute an action closure:
# - 0 items  → no-op
# - 1 item   → run action directly
# - 2+ items → fuzzy-pick via sk, then run action
def _pick-exec [action: closure]: list<string> -> nothing {
    let matches = $in
    match ($matches | length) {
        0 => null
        1 => { do $action ($matches | first) }
        _ => {
            let pick = ($matches | str join (char newline) | sk | str trim)
            if ($pick | is-not-empty) { do $action $pick }
        }
    }
}

# Open in hx the result of fd
def fhx [pattern: string = ""]: nothing -> nothing {
    fd $pattern | lines | _pick-exec {|f| hx $f }
}

# Open in antigravity-ide the result of fd for .code-workspace files
def agy-ide [pattern: string = ""]: nothing -> nothing {
    fd -e code-workspace $pattern $env.HOME | lines | _pick-exec {|w| antigravity-ide $w }
}
