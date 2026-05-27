#!/usr/bin/env nu
# prepare_memtest.nu — Setup memtest86+ on NixOS systemd-boot

let config_file = "/etc/nixos/src/system/core.nix"
let boot_dir = "/boot"

def banner [title: string]: nothing -> nothing {
    print ("\n" + (ansi cyan_bold) + "━━ " + $title + " ━━" + (ansi reset))
}

banner "Checking NixOS Configuration"

if (not ($config_file | path exists)) {
    print $"Error: ($config_file) not found."
    exit 1
}

let content = (open $config_file)
if ($content | str contains "boot.loader.systemd-boot.memtest86.enable = true") {
    print "✓ memtest86 already enabled in config."
} else {
    print "✗ memtest86 NOT enabled in config."
    print $"Action: Adding 'boot.loader.systemd-boot.memtest86.enable = true;' to ($config_file)"
    
    # Surgical insert before the closing brace or after systemd-boot.enable
    # Note: This is an agent script, but the user wants it to 'work as expected'
    # I will use a simple sed-like replacement in the script logic or instructions.
    print "Run this to apply change:"
    print $"  sed -i '/systemd-boot.enable = true;/a \    boot.loader.systemd-boot.memtest86.enable = true;' ($config_file)"
}

banner "Applying Configuration"
print "Next step: Run 'nh os switch' to generate the EFI entry."
print "Command: nh os switch"

banner "Verification (Post-Switch)"
print "After switching, check if the binary exists:"
print $"  sudo ls ($boot_dir) | rg memtest"

banner "Tonight's Instructions"
print "1. Run: nh os switch"
print "2. Verify: sudo ls /boot | rg memtest"
print "3. Reboot: sudo reboot"
print "4. Select 'Memtest86+' in the boot menu."
print "5. Let it run for 4+ passes (overnight)."
