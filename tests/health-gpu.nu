#!/usr/bin/env nu
# tests/health-gpu.nu — GPU health scan based on check_gpu.py
use _lib.nu *

def test-nvidia-smi [] {
    if (which nvidia-smi | is-empty) { return (skip "NVIDIA SMI" "nvidia-smi not found") }
    let out = (^nvidia-smi | complete)
    check "nvidia-smi executes" ($out.exit_code == 0) ($out.stderr | str trim)
}

def test-power [] {
    if (which nvidia-smi | is-empty) { return [] }
    let out = (^nvidia-smi --query-gpu=power.draw,power.limit,utilization.gpu --format=csv,noheader,nounits | complete)
    
    if $out.exit_code != 0 {
         return [(fail "GPU power query failed" ($out.stderr | str trim))]
    }
    let data = ($out.stdout | str trim | split row ",")
    if ($data | length) < 3 {
        return [(fail "GPU power query returned unexpected format" $out.stdout)]
    }
    
    let draw = ($data | get 0 | str trim | into float)
    let util = ($data | get 2 | str trim | into float)

    [
        (check $"Power draw: ($draw)W" ($draw <= 25.0) $"High idle power draw: ($draw)W")
        (check $"Utilization: ($util)%" ($util <= 15.0) $"High idle utilization: ($util)%")
    ]
}

def test-pytorch [] {
    let ai_dir = ("~/docs/lab/ai" | path expand)
    if not ($ai_dir | path exists) { return [(skip "PyTorch check" "AI lab directory missing")] }
    
    let out = (do { 
        cd $ai_dir
        ^uv run python3 -c "import torch; print(f\"OK: {torch.__version__} (CUDA: {torch.cuda.is_available()})\")"
    } | complete)
    
    if $out.exit_code == 0 {
        let res = ($out.stdout | str trim)
        [(check $"PyTorch CUDA ($res)" ($res | str contains "CUDA: True") $res)]
    } else {
        [(fail "PyTorch check failed" ($out.stderr | str trim))]
    }
}

def test-offload [] {
    let glxinfo = (which glxinfo)
    if ($glxinfo | is-empty) { return [(skip "Offload check" "glxinfo missing")] }

    let igpu_out = (^glxinfo -B | complete)
    let dgpu_avail = (which nvidia-offload | is-not-empty)

    mut results = []

    if $igpu_out.exit_code == 0 {
        let renderer = ($igpu_out.stdout | lines | find "OpenGL renderer string" | first | str replace "OpenGL renderer string: " "" | str trim)
        $results = ($results | append (check $"iGPU Renderer: ($renderer)" (not ($renderer | str downcase | str contains "nvidia")) $"Renderer is NVIDIA: ($renderer)"))
    } else {
        $results = ($results | append (fail "glxinfo failed" ($igpu_out.stderr | str trim)))
    }

    if $dgpu_avail {
        let dgpu_out = (^nvidia-offload glxinfo -B | complete)
        if $dgpu_out.exit_code == 0 {
            let renderer = ($dgpu_out.stdout | lines | find "OpenGL renderer string" | first | str replace "OpenGL renderer string: " "" | str trim)
            $results = ($results | append (check $"dGPU offload works: ($renderer)" ($renderer | str downcase | str contains "nvidia") $"Renderer is NOT NVIDIA: ($renderer)"))
        } else {
            $results = ($results | append (fail "nvidia-offload glxinfo failed" ($dgpu_out.stderr | str trim)))
        }
    } else {
        $results = ($results | append (skip "dGPU offload" "nvidia-offload command not found"))
    }

    $results
}

def test-env-clean [] {
    let bad_vars = ["__GLX_VENDOR_LIBRARY_NAME", "__EGL_VENDOR_LIBRARY_JSON_FILE"]
    let issues = ($bad_vars | each {|v|
        if ($env | get -o $v | is-not-empty) { $"($v) is set" } else { null }
    } | compact)

    check "Environment clean" ($issues | is-empty) ($issues | str join ", ")
}

def main [] {
    audit "GPU Health" "cyan_bold" { [
        (test-nvidia-smi)
        ...(test-pytorch)
        ...(test-power)
        ...(test-offload)
        (test-env-clean)
    ] }
}
