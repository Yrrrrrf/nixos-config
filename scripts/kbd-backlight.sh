#!/usr/bin/env bash
#
# A helper script to manage keyboard backlight for Hyprland in a NON-CYCLIC way.
# It checks the current state and will not wrap around from high to off or vice-versa.

# Define the ordered brightness levels in an array. This is our source of truth.
# Note: "Med" is used instead of "Medium" to match the asusctl command.
readonly levels=("Off" "Low" "Med" "High")

# --- FUNCTION: Get the current brightness level ---
# This is a more robust way to parse the output of `asusctl -k`.
get_current_level() {
    # Isolate the line with the brightness, cut the string after the colon, and trim whitespace.
    asusctl -k | grep "Current keyboard led brightness:" | cut -d':' -f2 | xargs
}

# --- FUNCTION: Set the brightness level ---
# Takes a level like "Low" as an argument and sets it via asusctl.
set_brightness() {
    local new_level_capitalized="$1"
    # The asusctl command expects a lowercase argument (e.g., "low", "med").
    local new_level_lowercase
    new_level_lowercase=$(echo "$new_level_capitalized" | tr '[:upper:]' '[:lower:]')

    # Set the new brightness level.
    asusctl --kbd-bright "$new_level_lowercase"
}

# --- Main Logic ---

# 1. Get the current level as a string (e.g., "Med").
current_level=$(get_current_level)
current_index=-1

# 2. Find the numerical index of the current level in our array.
for i in "${!levels[@]}"; do
   if [[ "${levels[$i]}" == "$current_level" ]]; then
       current_index=$i
       break
   fi
done

# If the current level wasn't found in our array, exit to be safe.
if [[ $current_index -eq -1 ]]; then
    echo "Error: Could not determine current backlight level from 'asusctl -k'. Output was: $current_level" >&2
    exit 1
fi

# 3. Determine the new index based on user input.
case "$1" in
  --up)
    # If we are NOT already at the highest level...
    if [[ $current_index -lt $((${#levels[@]} - 1)) ]]; then
        # ...calculate the next index and set the new brightness.
        new_index=$((current_index + 1))
        set_brightness "${levels[$new_index]}"
    fi
    ;;

  --down)
    # If we are NOT already at the lowest level...
    if [[ $current_index -gt 0 ]]; then
        # ...calculate the previous index and set the new brightness.
        new_index=$((current_index - 1))
        set_brightness "${levels[$new_index]}"
    fi
    ;;

  *)
    # If the argument is not --up or --down, show a usage message.
    echo "Usage: $0 [--up | --down]"
    exit 1
    ;;
esac
