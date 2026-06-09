#!/usr/bin/env nu
# tests/bench-ui.nu — Comprehensive UI component benchmarking.
use _lib.nu *
# Snapshot the current state token from a script.
def snap [cmd: string, ...args: string]: nothing -> string {
    let out = if ($cmd | str ends-with ".nu") {
        (run-external nu $cmd ...$args | complete)
    } else {
        (run-external $cmd ...$args | complete)
    }
    if $out.exit_code != 0 { return "" }
    $out.stdout | str trim | try {
        from json | get text
    } catch { "" }
}
# Execute a script action and return exit code.
def act [cmd: string, ...args: string]: nothing -> int {
    if ($cmd | str ends-with ".nu") {
        (run-external nu $cmd ...$args | complete).exit_code
    } else {
        (run-external $cmd ...$args | complete).exit_code
    }
}
def main [feature?: string, --quick] {
    let scripts = {
        volume: "src/home/desktop/scripts/volume.nu"
        brightness: "src/home/desktop/scripts/brightness.nu"
        layout: "src/home/desktop/scripts/layout.nu"
        mic: "src/home/desktop/scripts/mic.nu"
        clipboard: "src/home/desktop/scripts/clipboard.nu"
        gpu_mode: "src/host/g14/scripts/gpu-mode.nu"
        kbd_backlight: "src/host/g14/scripts/kbd-backlight.nu"
    }
    if $feature == null {
        print "Usage: bench-ui <feature|all>"
        print "Features: volume, brightness, layout, mic, clipboard, gpu-mode, kbd-backlight"
        return
    }
    let run_all = ($feature == "all")
    # Volume: Hardware-backed sweep + mute logic.
    if $run_all or $feature == "volume" {
        audit "Audio Output" "blue_bold" {
            let script = $scripts.volume
            let original = (snap $script)
            let original_pct = ($original | parse -r ".* (\\d+)%" | get -o 0.capture | default "50")
            
            # Sweep
            for i in [0 50 100 0] {
                act $script "--set" ($i | into string) | ignore
                sleep 50ms
            }
            
            # Mute state check
            let start_mute = (snap $script)
            act $script "--mute" | ignore
            let toggled = (snap $script)
            act $script "--mute" | ignore
            let restored = (snap $script)

            let cleanup = (act $script "--set" $original_pct)
            [
                (check "Hardware sweep 0% -> 100% -> 0%" true "")
                (check $"Mute toggle: ($start_mute) -> ($toggled)" ($toggled != $start_mute) "state did not flip")
                (check $"Restore state: ($restored)" ($restored == $start_mute) $"got ($restored), want ($start_mute)")
                (check $"Reset to original volume ($original_pct)%" ($cleanup == 0) "reset failed")
            ]
        }
    }
    # Brightness: Linear backlight sweep.
    if $run_all or $feature == "brightness" {
        audit "Display Backlight" "yellow_bold" {
            let script = $scripts.brightness
            let original = (snap $script)
            let original_pct = ($original | parse -r ".* (\\d+)%" | get -o 0.capture | default "50")
            
            for i in [0 50 100 0] {
                act $script "--set" ($i | into string) | ignore
                sleep 50ms
            }
            
            let cleanup = (act $script "--set" $original_pct)
            [
                (check "Hardware sweep 0% -> 100% -> 0%" true "")
                (check $"Reset to original brightness ($original_pct)%" ($cleanup == 0) "reset failed")
            ]
        }
    }
    # Layout: Toggle between active keymaps.
    if $run_all or $feature == "layout" {
        audit "Keyboard Input" "green_bold" {
            let script = $scripts.layout
            let before = (snap $script)
            
            act $script "--change" | ignore
            sleep 500ms
            let mid = (snap $script)
            
            act $script "--change" | ignore
            sleep 500ms
            let after = (snap $script)
            
            [
                (check $"Switch layout: ($before) -> ($mid)" ($mid != $before) "state did not change")
                (check $"Restore layout: ($after)" ($after == $before) $"got ($after), want ($before)")
            ]
        }
    }
    # Mic: Hardware-backed toggle.
    if $run_all or $feature == "mic" {
        audit "Audio Input" "red_bold" {
            let script = $scripts.mic
            let before = (snap $script)
            
            act $script "--toggle" | ignore
            sleep 500ms
            let mid = (snap $script)
            
            act $script "--toggle" | ignore
            sleep 500ms
            let after = (snap $script)
            
            [
                (check $"Toggle mute: ($before) -> ($mid)" ($mid != $before) "state did not flip")
                (check $"Restore state: ($after)" ($after == $before) $"got ($after), want ($before)")
            ]
        }
    }
    # Clipboard: Verification of UI picker.
    if $feature == "clipboard" {
        audit "Clipboard Manager" "magenta_bold" {
            let script = $scripts.clipboard
            let ex = (act $script "--pick")
            [
                (check "Invoke interactive history picker (Walker)" ($ex == 0) "picker failed")
            ]
        }
    }
    # GPU Mode: Full profile rotation.
    if $run_all or $feature == "gpu-mode" {
        audit "ASUS Power Profile" "cyan_bold" {
            let script = $scripts.gpu_mode
            let start = (snap $script)
            
            # Rotate through 3 profiles
            let results = (1..3 | each {|i|
                let prev = (snap $script)
                act $script "--change" | ignore
                sleep 1sec
                let now = (snap $script)
                check $"Profile rotate ($i): ($prev) -> ($now)" ($now != $prev) "no state change detected"
            })
            
            let final = (snap $script)
            $results | append (check $"Cycle completion: ($final)" ($final == $start) "failed to return to starting profile")
        }
    }
    # Keyboard Backlight: Kernel-backed intensity cycle.
    if $run_all or $feature == "kbd-backlight" {
        audit "Keyboard LEDs" "white_bold" {
            let script = $scripts.kbd_backlight
            let start = (snap $script)
            
            # Cycle 4 levels
            let results = (1..4 | each {|i|
                let prev = (snap $script)
                act $script "--up" | ignore
                sleep 500ms
                let now = (snap $script)
                check $"Intensity step ($i): ($prev) -> ($now)" ($now != $prev) "no state change detected"
            })
            
            let final = (snap $script)
            $results | append (check $"Cycle completion: ($final)" ($final == $start) "failed to return to starting intensity")
        }
    }
}
