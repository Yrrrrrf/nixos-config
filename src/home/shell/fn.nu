# home/shell/fn.nu

# Convert any file to .txt (same name, new extension)
def to-txt [file: path] {
    let out = ($file | path parse | update extension "txt" | path join)
    open --raw $file | save $out
}

# Load a .env file into current environment
def load-env-file [file: path] {
    open $file
        | lines
        | where {|l| not ($l | str starts-with '#') and $l != ''}
        | parse "{key}={val}"
        | transpose -r
        | load-env
}
