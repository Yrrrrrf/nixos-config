{...}: {
  flake.nixosModules.nvidia = {
    config,
    pkgs,
    ...
  }: {
    nix.settings = {
      extra-substituters = ["https://cuda-maintainers.cachix.org"];
      extra-trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9jyUG0VpZa7CNfq55E="
      ];
    };

    hardware = {
      graphics.enable = true;

      nvidia = {
        open = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable // {
          open = config.boot.kernelPackages.nvidiaPackages.stable.open.overrideAttrs (old: {
            postPatch =
              (old.postPatch or "")
              + ''
                substituteInPlace kernel-open/nvidia/os-interface.c \
                  --replace-fail 'strncpy(buf, current->comm, len - 1);' 'strscpy(buf, current->comm, len);'
                substituteInPlace kernel-open/nvidia/linux_nvswitch.c \
                  --replace-fail 'strncpy(regkey_val, regkey_val_start, regkey_val_len);' 'memcpy(regkey_val, regkey_val_start, regkey_val_len);' \
                  --replace-fail 'return strncpy(dest, src, length);' 'strscpy(dest, src, length); return dest;'
                substituteInPlace kernel-open/nvidia-modeset/nvidia-modeset-linux.c \
                  --replace-fail 'return strncpy(dest, src, n);' 'strscpy(dest, src, n); return dest;'
                substituteInPlace kernel-open/nvidia-uvm/uvm_pmm_gpu.c \
                  --replace-fail 'strncpy(chunk_split_cache[level].name, "uvm_gpu_chunk_t", sizeof(chunk_split_cache[level].name) - 1);' 'strscpy(chunk_split_cache[level].name, "uvm_gpu_chunk_t", sizeof(chunk_split_cache[level].name));'

                substituteInPlace kernel-open/conftest.sh \
                  --replace-fail 'struct drm_atomic_state *state' 'struct drm_atomic_commit *state'

                sed -i '/#define __NVIDIA_DRM_CONFTEST_H__/a \
#include <linux/version.h>\
#if LINUX_VERSION_CODE >= KERNEL_VERSION(7, 2, 0)\
#define drm_atomic_state drm_atomic_commit\
#define drm_atomic_state_alloc drm_atomic_commit_alloc\
#define drm_atomic_state_init drm_atomic_commit_init\
#define drm_atomic_state_clear drm_atomic_commit_clear\
#define drm_atomic_state_default_clear drm_atomic_commit_default_clear\
#define drm_atomic_state_default_release drm_atomic_commit_default_release\
#define drm_atomic_state_put drm_atomic_commit_put\
#endif' kernel-open/nvidia-drm/nvidia-drm-conftest.h
              '';
          });
        };
      };
    };

    programs.nix-ld.libraries = with pkgs; [
      linuxPackages.nvidia_x11
      cudaPackages.cudatoolkit
      cudaPackages.cudnn
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:65:00.0", SYMLINK+="dri/igpu"
      SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"
    '';
  };
}
