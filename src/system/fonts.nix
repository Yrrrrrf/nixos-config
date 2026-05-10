{...}: {
  flake.nixosModules.fonts = {pkgs, ...}: {
    # --- Font Configuration ---
    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.lilex
      nerd-fonts.iosevka
      nerd-fonts.hurmit
      nerd-fonts.heavy-data
      nerd-fonts.terminess-ttf
    ];
  };
}
