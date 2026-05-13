{lib, ...}: (import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "iot";
  extraPackages = pkgs: [pkgs.platformio];
}
