{ lib
, stdenv
, requireFile
, dpkg
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
# Common dependencies for GUI/Electron apps
, alsa-lib
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libdrm
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, xorg
, src  # This will be passed from flake.nix
}:

stdenv.mkDerivation rec {
  pname = "antigravity";
  version = "custom";

  inherit src;

  # These tools help unpack the .deb and fix the binaries to work on NixOS
  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    wrapGAppsHook3
  ];

  # Runtime dependencies (Libs the app needs to run)
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxshmfence
  ];

  # 1. Unpack the .deb file
  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  # 2. Install the files to the Nix store
  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    runHook postInstall
  '';

  # 3. Fix internal paths and libraries
  # We need to ensure the binary can find the libs listed in buildInputs
  postFixup = ''
    # Adjust this path based on where the main binary actually lives inside the .deb
    # Usually it's in $out/bin/antigravity or $out/opt/antigravity/...
    
    # If the binary is in /opt, we need to link it to /bin so you can type 'antigravity'
    if [ -d "$out/opt/antigravity" ]; then
      mkdir -p $out/bin
      ln -s $out/opt/antigravity/antigravity $out/bin/antigravity
    fi
  '';

  meta = with lib; {
    description = "Antigravity Tool";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
    mainProgram = "antigravity";
  };
}
