{
  pkgs,
  lib,
  ...
}: {
  gui = with pkgs; [
    wayland           # audit-pending: consumed by: Wayland compositor / GUI apps
    libxkbcommon      # audit-pending: consumed by: XKB keyboard translation
    xorg.libX11       # audit-pending: consumed by: X11 legacy apps
    xorg.libXcursor   # audit-pending: consumed by: X11 cursor themes
    xorg.libXrandr    # audit-pending: consumed by: X11 screen configuration
    xorg.libXi        # audit-pending: consumed by: X11 input devices
    xorg.libXinerama  # audit-pending: consumed by: X11 multi-monitor
    libglvnd          # audit-pending: consumed by: OpenGL wrapper
    libGL             # audit-pending: consumed by: OpenGL applications
    alsa-lib          # audit-pending: consumed by: Audio applications
    glib              # audit-pending: consumed by: GTK / GNOME apps
    SDL2              # audit-pending: consumed by: Games / Media apps
    SDL2_ttf          # audit-pending: consumed by: SDL text rendering
    SDL2_image        # audit-pending: consumed by: SDL image loading
    SDL2_mixer        # audit-pending: consumed by: SDL audio
    SDL2_gfx          # audit-pending: consumed by: SDL graphics primitives
  ];
  build = with pkgs; [
    systemd.dev       # audit-pending: consumed by: programs linking to libsystemd
    pkg-config        # audit-pending: consumed by: C/C++ builds resolving libs
    alsa-lib.dev      # audit-pending: consumed by: Audio development headers
    wayland.dev       # audit-pending: consumed by: Wayland development headers
    xorg.libxcb       # audit-pending: consumed by: X11 C-binding development
    fontconfig        # audit-pending: consumed by: Font rendering / resolution
    freetype          # audit-pending: consumed by: Font rendering engine
    qt6.qtbase        # audit-pending: consumed by: Qt6 applications
    qt6.qtwayland     # audit-pending: consumed by: Qt6 Wayland integration
    libjpeg           # audit-pending: consumed by: JPEG image processing
    libpng            # audit-pending: consumed by: PNG image processing
    giflib            # audit-pending: consumed by: GIF image processing
  ];
}
