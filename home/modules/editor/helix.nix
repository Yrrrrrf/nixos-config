# /etc/nixos/modules/home/editor/helix.nix
#
# This module declaratively manages the configuration for the Helix text editor.
# It enables the program and populates its language configuration by reading and
# parsing the 'languages.toml' file located in the same directory.

{ pkgs, ... }:

{
  # The 'programs.helix' options are provided by Home Manager.
  programs.helix = {
    enable = true; # Manages the Helix configuration file at ~/.config/helix/config.toml.

    # This is the most robust way to handle complex TOML configurations in Nix.
    # 1. `builtins.readFile ./languages.toml`: Reads the raw text content of the file.
    # 2. `builtins.fromTOML (...)`: Parses that text content into a Nix attribute set,
    #    which is the format the 'languages' option expects.
    languages = builtins.fromTOML (builtins.readFile ./languages.toml);

    # By managing the language configuration here, we ensure that Helix is always
    # set up correctly with all its language servers after a 'nixos-rebuild'.
    # For general settings (theme, editor behavior), you would add them here, like:
    # settings = {
    #   theme = "base16";
    #   editor = {
    #     line-number = "relative";
    #     cursor-shape = {
    #       insert = "bar";
    #       normal = "block";
    #       select = "underline";
    #     };
    #   };
    # };
  };

  # --- Language Servers & Formatters ---
  # To make this module self-contained, we list all the Language Server Protocol (LSP)
  # servers and formatters that are specified in 'languages.toml' as packages.
  # This ensures they are installed and available in the user's PATH for Helix to use.
  home.packages = with pkgs; [
    # LSPs
    pyright
    # rocmPackages.llvm.clang-tools
    gopls
    typescript-language-server
    vscode-langservers-extracted # Provides LSPs for css, html, json
    svelte-language-server
    taplo # TOML LSP
    nil # Nix LSP
    nixfmt
    sqls # SQL LSP
    bash-language-server

    tinymist # Typst files

    asm-lsp # Assembly LSP
    kotlin-language-server
    hyprls

    # Formatters
    nixpkgs-fmt # Formatter for Nix files
    # (ruff.with-extensions (exts: [ exts.format ])) # Python formatter
  ];
}
