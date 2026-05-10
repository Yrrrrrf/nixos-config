{
  pkgs,
  lib,
  ...
}: {
  gui = with pkgs; [
    wayland # audit-pending: consumed by: Wayland compositor / GUI apps
    libxkbcommon # audit-pending: consumed by: XKB keyboard translation
    libglvnd # audit-pending: consumed by: OpenGL wrapper
    libGL # audit-pending: consumed by: OpenGL applications
    alsa-lib # audit-pending: consumed by: Audio applications
    glib # audit-pending: consumed by: GTK / GNOME apps
  ];
  build = with pkgs; [
    systemd.dev # audit-pending: consumed by: programs linking to libsystemd
    pkg-config # audit-pending: consumed by: C/C++ builds resolving libs
    alsa-lib.dev # audit-pending: consumed by: Audio development headers
    wayland.dev # audit-pending: consumed by: Wayland development headers
    fontconfig # audit-pending: consumed by: Font rendering / resolution
  ];
}
