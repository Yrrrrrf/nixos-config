{ pkgs, ... }: {
  nav = with pkgs; [ eza fd broot ];
  view = with pkgs; [ bat hexyl ];
  text = with pkgs; [ ripgrep sd jaq choose ];
  git = with pkgs; [ gh gitui delta git-cliff ];
  system = with pkgs; [ bottom procs dust fastfetch ];
  net = with pkgs; [ xh gping bandwhich killport ];
  archive = with pkgs; [ ouch p7zip ];
  bench = with pkgs; [ hyperfine tokei ];
  shell = with pkgs; [ skim tealdeer ];
  rust-dev = with pkgs; [ bacon mprocs ];
  misc = with pkgs; [ ttyper wev unimatrix bluetui impala openssl ];
}
