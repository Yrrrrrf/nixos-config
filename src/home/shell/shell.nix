{inputs, ...}: {
  flake.homeModules.shell = {...}: {
    imports = [
      inputs.agenix.homeManagerModules.default
      # Add nu shell module as default shell
      inputs.self.homeModules.nushell
    ];

    programs = {
      # Enable companion tools for the shell
      atuin.enable = true;
      zoxide.enable = true;
      starship.enable = true;

      # Enable common shell tools
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      nix-index.enable = true;

      difftastic = {
        enable = true;
        git.enable = true;
      };
      fastfetch.enable = true;

      helix = {
        enable = true;
        settings = {
          editor = {
            line-number = "relative";
            mouse = true;
            cursorline = true;
            bufferline = "multiple";
            true-color = true;
            color-modes = true;
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            indent-guides = {
              render = true;
              character = "╎";
            };
            lsp = {
              display-messages = true;
              display-inlay-hints = true;
            };
          };
          keys.normal = {
            C-y = [
              ":sh rm -f /tmp/unique-file"
              ":insert-output yazi \"%{buffer_name}\" --chooser-file=/tmp/unique-file"
              ":sh printf \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
              ":open %sh{cat /tmp/unique-file}"
              ":redraw"
              ":set mouse false"
              ":set mouse true"
            ];
          };
        };
      };

      yazi = {
        enable = true;
        settings = {
          mgr = {
            show_hidden = true;
          };
          opener = {
            edit = [
              {
                run = "hx \"$@\"";
                block = true;
              }
            ];
          };
          open = {
            rules = [
              {
                mime = "text/*";
                use = "edit";
              }
              {
                mime = "inode/x-empty";
                use = "edit";
              }
              {
                url = "*";
                use = "edit";
              }
            ];
          };
        };
      };
    };

    # External config files
    xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch.jsonc;
  };
}
