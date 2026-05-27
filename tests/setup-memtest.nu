#!/usr/bin/env nu
# enable_memtest.nu — Automate memtest86+ enabling in NixOS config

let config_file = "/etc/nixos/src/system/core.nix"

if (not ($config_file | path exists)) {
    print $"Error: ($config_file) not found."
    exit 1
}

let content = (open $config_file)
if ($content | str contains "boot.loader.systemd-boot.memtest86.enable = true") {
    print "✓ memtest86 already enabled."
} else {
    print $"Enabling memtest86 in ($config_file)..."
    # Insert after systemd-boot.enable
    sudo sed -i '/systemd-boot.enable = true;/a \    boot.loader.systemd-boot.memtest86.enable = true;' $config_file
    print "✓ Config updated."
}

print "Ready for tonight. Just run: nh os switch && sudo reboot"
