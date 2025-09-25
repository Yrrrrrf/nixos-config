#!/usr/bin/env bash
#
# Master function loader for Zsh.
# This script sources all other function library files.

# Get the directory where this script is located to reliably source other files.
SCRIPT_DIR="$(dirname "$0")"

source "$SCRIPT_DIR/load-env.sh"
source "$SCRIPT_DIR/to-txt.sh"