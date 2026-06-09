#!/usr/bin/env nu

# Converts HSV to RGB list [r, g, b]
export def hsv-to-rgb [h: float, s: float, v: float] {
    let c = $v * $s
    let h_prime = $h / 60.0
    let x = $c * (1.0 - (($h_prime mod 2.0) - 1.0 | math abs))
    let m = $v - $c

    let rgb = if $h_prime < 1.0 {
        [$c, $x, 0.0]
    } else if $h_prime < 2.0 {
        [$x, $c, 0.0]
    } else if $h_prime < 3.0 {
        [0.0, $c, $x]
    } else if $h_prime < 4.0 {
        [0.0, $x, $c]
    } else if $h_prime < 5.0 {
        [$x, 0.0, $c]
    } else {
        [$c, 0.0, $x]
    }

    $rgb | each { |it| (($it + $m) * 255.0 | math round | into int) }
}

# Converts RGB list to hex string
export def to-hex [rgb: list<int>] {
    $rgb | each { |it| 
        $it | format number --no-prefix | get lowerhex | fill --alignment right --character "0" --width 2 
    } | str join ""
}

# Cycles through the RGB spectrum
export def run-cycle [
    --steps: int = 36      # Number of steps in the cycle
    --delay: duration = 100ms # Delay between steps
    --loops: int = 1       # Number of times to loop the spectrum
] {
    print $"Starting RGB spectrum cycle with ($steps) steps and ($delay) delay."
    
    for l in 1..$loops {
        if $loops > 1 { print $"Loop ($l)/($loops)" }
        for i in 0..($steps - 1) {
            let hue = (($i | into float) * (360.0 / ($steps | into float)))
            let rgb = (hsv-to-rgb $hue 1.0 1.0)
            let hex = (to-hex $rgb)
            
            # Using a single line update to avoid flooding the terminal
            print -n $"\rCurrent Color: #($hex) Hue: ($hue | math round)   "
            
            asusctl aura effect static -c $hex --zone 0
            sleep $delay
        }
    }
    print "\nFinished cycle. Setting final color to Turquoise..."
    asusctl aura effect static -c "00DFEE" --zone 0
    print "Done!"
}

# Allow running as a script
def main [
    --steps: int = 36
    --delay: duration = 100ms
    --loops: int = 1
] {
    run-cycle --steps $steps --delay $delay --loops $loops
}
