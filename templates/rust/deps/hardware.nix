# Dependencies for Rust hardware/embedded development
{ pkgs }: with pkgs; [
  # Cross-compilation toolchain for ARM
  # (example for Raspberry Pi)
  pkgsCross.armv7l-hf-multiplatform.stdenv.cc

  # Tools for flashing and debugging
  openocd
  gdb
]
