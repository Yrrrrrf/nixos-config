# /etc/nixos/resources/antigravity.nix
#
# Custom derivation for the official Google Antigravity IDE.
# Built from the Linux x64 tar.gz (no .deb available in direct downloads).
#
# Usage in flake.nix overlay:
#   antigravity = prev.callPackage ./resources/antigravity.nix {};

{ stdenv, lib, autoPatchelfHook, makeWrapper,
  glib, nss, nspr, dbus, atk, cups, libdrm,
  xorg, libxkbcommon, expat, wayland, alsa-lib,
  mesa, gtk3, pango, cairo, libGL,
}:

stdenv.mkDerivation rec {
  pname   = "antigravity";
  version = "1.18.3";

  src = ./assets/antigravity-1.18.3-linux-x64.tar.gz;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    stdenv.cc.cc.lib
    glib nss nspr dbus atk cups libdrm
    xorg.libX11 xorg.libXcomposite xorg.libXdamage
    xorg.libXext xorg.libXfixes xorg.libXrandr xorg.libxcb
    libxkbcommon expat wayland alsa-lib mesa gtk3 pango cairo libGL
  ];

  dontBuild     = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/antigravity $out/bin
    cp -r . $out/lib/antigravity

    makeWrapper $out/lib/antigravity/antigravity $out/bin/antigravity \
      --set ANTIGRAVITY_NO_SANDBOX 1

    mkdir -p $out/share/applications $out/share/pixmaps

    if [ -f $out/lib/antigravity/resources/antigravity.png ]; then
      cp $out/lib/antigravity/resources/antigravity.png \
         $out/share/pixmaps/antigravity.png
    fi

    cat > $out/share/applications/antigravity.desktop << EOF
    [Desktop Entry]
    Name=Antigravity
    Comment=Google's AI-powered IDE
    Exec=$out/bin/antigravity
    Icon=antigravity
    Type=Application
    Categories=Development;IDE;
    StartupWMClass=Antigravity
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    description = "Google's official Antigravity AI IDE";
    homepage    = "https://idx.google.com";
    platforms   = [ "x86_64-linux" ];
    license     = licenses.unfree;
  };
}
