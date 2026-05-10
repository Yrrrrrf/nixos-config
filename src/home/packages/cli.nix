{lib, ...}: {
  options.flake.lib.pkgsets.cli = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.pkgsets.cli = {
    nav = pkgs:
      with pkgs; [
        eza
        fd
        broot
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
        p7zip
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
    misc = pkgs:
      with pkgs; [
        ttyper
        wev
        unimatrix
        bluetui
        impala
        openssl
      ];
  };
}
