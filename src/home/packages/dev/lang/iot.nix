{...}: {
  flake.homeModules."dev-lang-iot" = {pkgs, ...}: {
    home.packages = with pkgs; [
      platformio
    ];
  };
}
