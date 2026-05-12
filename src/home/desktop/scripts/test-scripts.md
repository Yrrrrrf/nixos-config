# Desktop Script Verification Guide

This document explains how to manually test and verify the Nushell scripts used by the desktop environment. Since these scripts are used by Waybar and Hyprland keybinds, they are designed to function as standalone CLI applications.

## General Usage
All scripts should be executed using `nu`:
```bash
nu src/home/desktop/scripts/<script-name>.nu [flags]
```

---

## 1. Keyboard Backlight (`kbd-backlight.nu`)
Manages the ASUS keyboard backlight levels (Off, Low, Med, High).

*   **Commands:**
    *   `nu kbd-backlight.nu --up`: Increases brightness by one level.
    *   `nu kbd-backlight.nu --down`: Decreases brightness by one level.
    *   `nu kbd-backlight.nu --get`: Returns JSON for Waybar.
*   **Expected Output (`--get`):**
    ```json
    {"level":"Off","icon":"󰌌"}
    ```
*   **Expected Behavior (`--up`/`--down`):**
    *   Prints to console: `Keyboard backlight set to: Low`.


## 2. Keyboard Layout (`kbd-layout.nu`)
Manages switching between US and MX (Intl) layouts.

*   **Commands:**
    *   `nu kbd-layout.nu --get`: Returns JSON for Waybar.
    *   `nu kbd-layout.nu --change`: Switches to the next layout and sends a notification.
*   **Expected Output (`--get`):**
    ```json
    {"key":"US","language":"English"}
    ```
*   **Expected Behavior (`--change`):**
    *   Prints to console: `Language set to: (US) English`.
    *   Desktop notification should appear with the same message.

## 3. Microphone Manager (`kbd-mic.nu`)
Toggles the default microphone and provides status.

*   **Commands:**
    *   `nu kbd-mic.nu --get-status`: Returns JSON for Waybar.
    *   `nu kbd-mic.nu --toggle`: Toggles mute state via SwayOSD.
*   **Expected Output (`--get-status`):**
    ```json
    {"status":"Active","icon":""}
    ```
*   **Expected Behavior (`--toggle`):**
    *   Prints to console: `Microphone status set to: Muted`.


## 4. Performance Profiles (`kbd-performance.nu`)
Manages ASUS performance profiles (Quiet, Balanced, Performance).

*   **Commands:**
    *   `nu kbd-performance.nu --get`: Returns JSON for Waybar.
    *   `nu kbd-performance.nu --change`: Cycles to the next profile.
*   **Expected Output (`--get`):**
    ```json
    {"profile":"Balanced","icon":"󰾅"}
    ```
*   **Expected Behavior (`--change`):**
    *   Prints to console: `Performance profile set to: Performance`.
    *   Desktop notification should appear.


## 5. Power Menu (`powermenu.nu`)
Executes system power actions.

*   **Commands:**
    *   `nu powermenu.nu Logout`: Exits Hyprland.
    *   `nu powermenu.nu Suspend`: Suspends the system.
    *   `nu powermenu.nu Reboot`: Reboots the system.
    *   `nu powermenu.nu Shutdown`: Powers off the system.
*   **Expected Behavior:**
    *   Immediate execution of the specified action.

## 6. Screenshot Utility (`screenshot.nu`)
Wrapper for `hyprshot` with notifications and clipboard integration.

*   **Commands:**
    *   `nu screenshot.nu --region`: Launches region selector.
    *   `nu screenshot.nu --screen`: Captures current monitor.
*   **Expected Behavior:**
    *   Prints to console: `Screenshot stored on: /home/user/Pictures/Screenshots/...`.
    *   Notification appears after capture.

    *   File saved in `~/Pictures/Screenshots/`.
    *   Image copied to clipboard.


---

## Hardening Notes
All ASUS-related scripts have been hardened with `ansi strip` to handle color codes in `asusctl` output and `first` to ignore log noise from the `zbus` background workers.
