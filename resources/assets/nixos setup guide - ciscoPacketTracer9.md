# 🎓 Cisco Packet Tracer 9: NixOS Setup Guide

This guide covers the temporary installation and eventual removal of Cisco Packet Tracer 9 on a NixOS Flake-based system.

## 1. The Concept: `requireFile`
Unlike open-source software (like Firefox or Git), Cisco Packet Tracer is **Proprietary (Unfree)** and sits behind a **Login Wall**. 

Nix cannot automatically download it because:
1. It requires a Cisco Networking Academy account to access the download.
2. The license prevents redistribution on public Nix mirrors.

To solve this, Nix uses a mechanism called `requireFile`. The package definition tells Nix: *"I know how to build this, but you must manually provide the `.deb` file first."*

## 2. Manual Installation Steps

### Step A: Download & Register
Once you have the `CiscoPacketTracer_900_Ubuntu_64bit.deb` file, you must manually register it in the Nix Store. This makes the file "known" to the system builder.

```bash
# Run this from the directory containing your assets
sudo nix-store --add-fixed sha256 resources/assets/CiscoPacketTracer_900_Ubuntu_64bit.deb
```

### Step B: Configuration Note
In our `flake.nix`, we added a specific **Overlay** to handle Packet Tracer 9. There are two critical parts to this:

1.  **Version Logic:** Packet Tracer 9 depends on an older version of `libxml2`. Since we are using the `unstable` channel, we had to explicitly permit this insecure dependency in the `permittedInsecurePackages` list.
2.  **Package Source:** Because we registered the file in Step A, we can simply call `unstable.ciscoPacketTracer9` without complex overrides.

**Current Flake Structure:**
```nix
permittedInsecurePackages = [
  "libxml2-2.13.9"             # Required for Packet Tracer 9
  "ciscoPacketTracer9-9.0.0"   # The package itself
];
```

## 3. Uninstallation (End of Semester)
When the semester is over and you no longer need the tool, follow these steps to clean your system:

### Step 1: Remove from Nix Config
1. Open `home/profiles/dev.nix` and remove `pkgs.ciscoPacketTracer9` from the `home.packages` list.
2. Open `flake.nix` and remove the `ciscoPacketTracer9` lines from your overlay.
3. Remove the `libxml2` and `ciscoPacketTracer9` entries from `permittedInsecurePackages`.

### Step 2: Rebuild
Apply the changes to remove the binary from your `$PATH`:
```bash
sudo nixos-rebuild switch --flake .#g14
```

### Step 3: Garbage Collection
To actually delete the large `.deb` and the installed files from your disk:
```bash
sudo nix-collect-garbage -d
```

### Step 4: Cleanup local files
Finally, delete the local installer to save space:
```bash
rm resources/assets/CiscoPacketTracer_900_Ubuntu_64bit.deb
```

***
*Note: This documentation was created to track the specific configuration required for PT9 during the Feb-Jun 2026 semester.*
