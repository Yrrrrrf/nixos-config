#!/usr/bin/env bash
# gpu-mode  —  thin wrapper over supergfxctl
case "$1" in
  off)    supergfxctl -m Integrated ;;   # dGPU fully powered down, max battery, requires logout
  hybrid) supergfxctl -m Hybrid ;;       # PRIME offload (the steady-state target)
  on)     supergfxctl -m AsusMuxDgpu ;;  # dGPU drives the display, requires reboot
  *)      supergfxctl -g ;;
esac


# Todo: Enhance this overall script
