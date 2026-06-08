# src/host/g14/disk.nix — Declarative partition layout for /dev/nvme0n1
# CT4000T710SSD8 — 4 TB NVMe (Crucial T710)
#
# Layout:
#   nvme0n1p1   1 GiB     FAT32 (ESP)   /boot
#   nvme0n1p2  32 GiB     linux-swap    [SWAP]
#   nvme0n1p3   rest      ext4          /
#
# WARNING: `disko --mode destroy,format,mount` will WIPE this disk.
# `nixos-rebuild switch` / `nh os switch` are safe — they never invoke disko.
{inputs, ...}: {
  flake.nixosModules.g14-disk = {imports, ...}: {
    imports = [inputs.disko.nixosModules.disko];


	disko.enableConfig = false;
    disko.devices.disk.nvme0n1 = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1GiB";
            type = "EF00"; # EFI System Partition
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };
          swap = {
            size = "32GiB";
            content = {
              type = "swap";
              discardPolicy = "both";
              resumeDevice = true;
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = ["defaults" "noatime"];
            };
          };
        };
      };
    };
  };
}
