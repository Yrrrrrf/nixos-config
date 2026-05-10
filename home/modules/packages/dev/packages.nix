{pkgs, ...}: {
  build = with pkgs; [pkg-config gcc openssl.dev];
  ides = with pkgs; [vscode jetbrains-toolbox gitkraken unityhub antigravity];
}
