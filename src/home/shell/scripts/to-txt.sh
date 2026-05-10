#!/usr/bin/env bash
#
# A library file containing the to-txt shell function.
# This file is intended to be sourced, not executed directly.

function to-txt {
  # This script copies one or more files to the ~/Downloads directory,
  # appending .txt extension while preserving the original extension.

  # --- CONFIGURATION ---
  local DEST_DIR="$HOME/Downloads"

  # --- FUNCTION LOGIC ---
  mkdir -p "$DEST_DIR"

  if [ "$#" -eq 0 ]; then
    echo "Usage: to-txt <file1> [file2] [file3] ..."
    echo "Example: to-txt configuration.nix home.nix"
    return 1
  fi

  # Loop through every argument provided to the FUNCTION.
  for input_file in "$@"; do
    if [ ! -f "$input_file" ]; then
        echo "Warning: '$input_file' is not a valid file. Skipping."
        continue
    fi

    local filename=$(basename "$input_file")
    local output_file="$DEST_DIR/${filename}.txt"

    cp "$input_file" "$output_file"
    echo "Copied '$input_file' to '$output_file'"
  done

  echo "---------------------"
  echo "All files processed and saved in '$DEST_DIR'"
}