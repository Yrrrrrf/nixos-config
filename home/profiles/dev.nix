# /etc/nixos/home/profiles/dev.nix
# The "Full Dev" profile. Imports the default config and adds dev packages.

{ pkgs, config, lib, ... }:

let
  cliPkgs = import ../modules/packages/cli.nix { inherit pkgs; };
  desktopPkgs = import ../modules/packages/desktop.nix { inherit pkgs; };
  devPkgs = import ../modules/packages/development.nix { inherit pkgs; };
  commonLibs = import ../modules/packages/common.nix { inherit pkgs lib; };
in
{
  imports = [
    ./default.nix
  ]; # import shared config

  # --- Session Variables ---
  home.sessionVariables = {
    LD_LIBRARY_PATH = lib.makeLibraryPath (
      commonLibs.buildLibs ++
      commonLibs.vulkanLibs ++
      devPkgs.cudaPkgs

    );
    PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" (
      commonLibs.buildLibs ++
      devPkgs.buildTools 
    );

    # --- ADD THESE CRITICAL GPU "SIGNPOST" VARIABLES ---
    # Tells applications where to find the NVIDIA OpenGL/Vulkan implementation.
    __EGL_VENDOR_LIBRARY_JSON_FILE = "${pkgs.linuxPackages.nvidia_x11}/share/glvnd/egl_vendor.d/10_nvidia.json";
    # A similar variable for the older GLX protocol (used by XWayland apps).
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };

  # --- Final Package List ---
  home.packages =
    commonLibs.guiLibs ++

    cliPkgs.replacements ++
    cliPkgs.tools ++

    cliPkgs.typingTools ++

    desktopPkgs.gui ++
    desktopPkgs.utils ++

    # Access the specific lists from your development.nix file
    devPkgs.buildTools ++
    devPkgs.ides ++

    # Flatten the 'lang' attribute set into a single list
    devPkgs.lang.kotlin ++
    devPkgs.lang.python ++
    devPkgs.lang.rust ++
    devPkgs.lang.go ++
    devPkgs.lang.web ++
    devPkgs.lang.iot ++

    [ pkgs.linuxPackages.nvidia_x11 ]

    ++ [ pkgs.ciscoPacketTracer9 ]
    
    ;
}
