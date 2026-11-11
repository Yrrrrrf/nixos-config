{...}: {
  flake.nixosModules.nvidia = {
    config,
    pkgs,
    ...
  }: {
    hardware = {
      graphics.enable = true;

      nvidia = {
        open = true;
        package =
          config.boot.kernelPackages.nvidiaPackages.stable
          // {
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
                                  substituteInPlace kernel-open/nvidia-uvm/uvm_hmm.c \
                                    --replace-fail '(vma->vm_flags & VM_SPECIAL)' '(vma->vm_flags & (VM_IO | VM_DONTEXPAND | VM_PFNMAP | VM_MIXEDMAP))' \
                                    --replace-fail 'is_vm_hugetlb_page(vma)' 'vma_is_hugetlb(vma)'
                                  substituteInPlace kernel-open/nvidia-drm/nvidia-drm-drv.c \
                                    --replace-fail '#include <drm/drm_fb_helper.h>' '#include <drm/drm_client_event.h>' \
                                    --replace-fail 'drm_fb_helper_set_suspend_unlocked(dev->fb_helper, 1);' 'drm_client_dev_suspend(dev);' \
                                    --replace-fail 'drm_fb_helper_set_suspend_unlocked(dev->fb_helper, 0);' 'drm_client_dev_resume(dev);'
                                  substituteInPlace kernel-open/nvidia-drm/nvidia-drm-crtc.c \
                                    --replace-fail 'static void nv_drm_plane_atomic_reset(struct drm_plane *plane)
                  {
                      struct nv_drm_plane_state *nv_plane_state =
                          nv_drm_calloc(1, sizeof(*nv_plane_state));

                      if (!nv_plane_state) {
                          return;
                      }

                      drm_atomic_helper_plane_reset(plane);

                      /*
                       * The drm atomic helper function allocates a state object that is the wrong
                       * size. Copy its contents into the one we allocated above and replace the
                       * pointer.
                       */
                      if (plane->state) {
                          nv_plane_state->base = *plane->state;
                          kfree(plane->state);
                          plane->state = &nv_plane_state->base;
                      } else {
                          kfree(nv_plane_state);
                      }
                  }' 'static struct drm_plane_state *nv_drm_plane_atomic_create_state(struct drm_plane *plane)
                  {
                      struct nv_drm_plane_state *nv_plane_state =
                          nv_drm_calloc(1, sizeof(*nv_plane_state));

                      if (!nv_plane_state) {
                          return ERR_PTR(-ENOMEM);
                      }

                      __drm_atomic_helper_plane_state_init(&nv_plane_state->base, plane);
                      return &nv_plane_state->base;
                  }' \
                                    --replace-fail '.reset                  = nv_drm_plane_atomic_reset,' '.atomic_create_state    = nv_drm_plane_atomic_create_state,' \
                                    --replace-fail 'static void nv_drm_atomic_crtc_reset(struct drm_crtc *crtc)
                  {
                      struct nv_drm_crtc_state *nv_state = nv_drm_crtc_state_alloc();

                      if (!nv_state) {
                          return;
                      }

                      drm_atomic_helper_crtc_reset(crtc);

                      /*
                       * The drm atomic helper function allocates a state object that is the wrong
                       * size. Copy its contents into the one we allocated above and replace the
                       * pointer.
                       */
                      if (crtc->state) {
                          nv_state->base = *crtc->state;
                          kfree(crtc->state);
                          crtc->state = &nv_state->base;
                      } else {
                          kfree(nv_state);
                      }
                  }' 'static struct drm_crtc_state *nv_drm_atomic_crtc_create_state(struct drm_crtc *crtc)
                  {
                      struct nv_drm_crtc_state *nv_state = nv_drm_crtc_state_alloc();

                      if (!nv_state) {
                          return ERR_PTR(-ENOMEM);
                      }

                      __drm_atomic_helper_crtc_state_init(&nv_state->base, crtc);
                      return &nv_state->base;
                  }' \
                                    --replace-fail '.reset                  = nv_drm_atomic_crtc_reset,' '.atomic_create_state    = nv_drm_atomic_crtc_create_state,'

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
