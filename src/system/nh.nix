{...}: {
  flake.nixosModules.nh = {pkgs, ...}: {
    programs.nh = {
      enable = true;
      flake = "/etc/nixos";
      clean.enable = true;
      clean.dates = "weekly";
      clean.extraArgs = "--keep 5 --keep-since 7d";
    };
  };
}
