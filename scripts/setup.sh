#!/usr/bin/env bash
# /etc/nixos/setup.sh
# 
# Reactive setup script for NixOS.
# Copies this repo to /etc/nixos, syncs disk UUIDs and devices, then rebuilds.
# 
# Usage: ./setup.sh [host_name]
#   host_name: Defaults to g14

set -euo pipefail

HOST="${1:-g14}"
TARGET="/etc/nixos"
# The source is the directory where this script is located (the repo root)
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HW_PATH="$TARGET/src/host/$HOST/hardware-configuration.nix"
DISK_PATH="$TARGET/src/host/$HOST/disk.nix"

echo "=== NixOS Reactive Setup ==="
echo "Source: $SRC_DIR"
echo "Target: $TARGET"
echo "Host:   $HOST"
echo "User Context: $(id -un) (UID: $(id -u))"

# 1. & 2. Backup and Copy (only if source is different from target)
if [ "$SRC_DIR" != "$TARGET" ]; then
    if [ -d "$TARGET" ]; then
        BACKUP="$TARGET.bak.$(date +%Y%m%d_%H%M%S)"
        echo "--> Backing up $TARGET to $BACKUP"
        sudo mv "$TARGET" "$BACKUP"
    fi
    echo "--> Copying $SRC_DIR to $TARGET"
    sudo mkdir -p "$TARGET"
    sudo cp -r "$SRC_DIR/." "$TARGET/"
else
    echo "--> Source and Target are the same ($TARGET), skipping copy."
fi

# 3. Reactive Disk/UUID Update
echo "--> Syncing disk configuration..."

# Detect UUIDs from the live system
root_uuid=$(findmnt -no UUID /)
boot_uuid=$(findmnt -no UUID /boot)
swap_uuid=$(lsblk -rno UUID,FSTYPE | awk '$2=="swap" {print $1}' | head -n1)
[ -z "$swap_uuid" ] && swap_uuid=$(sudo blkid -t TYPE=swap -o value -s UUID | head -n1 || echo "")

echo "    Detected UUIDs:"
echo "      /      : $root_uuid"
echo "      /boot  : $boot_uuid"
echo "      swap   : $swap_uuid"

# Detect main disk device (e.g., nvme0n1)
root_disk=$(lsblk -no PKNAME $(findmnt -no SOURCE / | head -n1) 2>/dev/null | head -n1 || echo "nvme0n1")
echo "    Detected Root Disk: /dev/$root_disk"

# Function to update or inject UUIDs into hardware-configuration.nix
update_hw_config() {
    local file=$1
    echo "    Updating $file"

    if [ -f "$file" ]; then
        echo "    Applying lib.mkForce and UUIDs..."
        
        # Use lib.mkForce to ensure these override Disko
        sudo sed -i "s|device = .*by-uuid/[^\"]*\"|device = lib.mkForce \"/dev/disk/by-uuid/${root_uuid}\"|" "$file"
        sudo sed -i "/fileSystems\.\"\/boot\"/,/};/ s|device = .*by-uuid/[^\"]*\"|device = lib.mkForce \"/dev/disk/by-uuid/${boot_uuid}\"|" "$file"
        if [ -n "$swap_uuid" ]; then
            sudo sed -i "/swapDevices/,/];/ s|device = .*by-uuid/[^\"]*\"|device = lib.mkForce \"/dev/disk/by-uuid/${swap_uuid}\"|" "$file"
        fi

        # Injection fallback
        if ! grep -q 'fileSystems."/"' "$file"; then
            echo "    Injecting missing filesystem blocks..."
            sudo sed -i '$d' "$file"
            cat <<EOF2 | sudo tee -a "$file" > /dev/null
  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/$root_uuid";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = lib.mkForce "/dev/disk/by-uuid/$boot_uuid";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };
  swapDevices = [
    { device = lib.mkForce "/dev/disk/by-uuid/$swap_uuid"; }
  ];
}
EOF2
        fi
    fi
}

if [ -f "$HW_PATH" ]; then
    update_hw_config "$HW_PATH"
else
    echo "    WARNING: $HW_PATH not found!"
fi

# Update disk.nix device path if it exists
if [ -f "$DISK_PATH" ]; then
    echo "    Updating device in $DISK_PATH to /dev/$root_disk"
    sudo sed -i "s|device = \"/dev/[^\"]*\"|device = \"/dev/$root_disk\"|" "$DISK_PATH"
fi

echo "=== Setup Complete! ==="
echo "Files have been copied and patched with lib.mkForce."
echo "No build was performed as requested."
