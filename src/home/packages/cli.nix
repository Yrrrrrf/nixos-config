{lib, ...}: {
  options.flake.lib.pkgsets.cli = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.pkgsets.cli = let
    nav = pkgs:
      with pkgs; [
        eza
        fd
      ];
    view = pkgs:
      with pkgs; [
        bat
        hexyl
      ];
    text = pkgs:
      with pkgs; [
        ripgrep
        sd
        jaq
        choose
      ];
    git = pkgs:
      with pkgs; [
        gh
        gitui
        lazygit
        delta
        git-cliff
      ];
    system = pkgs:
      with pkgs; [
        # btop-cuda
        bottom
        procs
        dust
        fastfetch
      ];
    net = pkgs:
      with pkgs; [
        xh
        gping
        bandwhich
        killport
      ];
    archive = pkgs:
      with pkgs; [
        ouch
      ];
    bench = pkgs:
      with pkgs; [
        hyperfine
        tokei
      ];
    shell = pkgs:
      with pkgs; [
        skim
        tealdeer
      ];
    rust-dev = pkgs:
      with pkgs; [
        bacon
        mprocs
      ];
    media = pkgs:
      with pkgs; [
        yt-dlp
      ];
    misc = pkgs:
      with pkgs; [
        ttyper
        wev
        unimatrix
        bluetui
        impala
        openssl
      ];
  in {
    inherit
      nav
      view
      text
      git
      system
      net
      archive
      bench
      shell
      rust-dev
      media
      misc
      ;
    core = pkgs:
      (nav pkgs)
      ++ (view pkgs)
      ++ (text pkgs)
      ++ (git pkgs)
      ++ (system pkgs)
      ++ (shell pkgs)
      ++ (media pkgs);
  };
}
