{...}: {
  flake.nixosModules.fonts = {pkgs, ...}: {
    # --- Font Configuration ---
    fonts.packages = with pkgs; [
      nerd-fonts.symbols-only
      nerd-fonts.fira-code
      noto-fonts-cjk-sans
    ];
  };
}
