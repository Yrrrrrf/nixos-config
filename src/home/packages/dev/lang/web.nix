{config, ...}: {
  config.flake.lib.dev.langs.web = {
    helix = config.flake.lib.helix.mkLangs [
      {
        name = "typescript";
        scope = "source.ts";
        file-types = [
          "ts"
          "tsx"
        ];
        roots = [
          "package.json"
          "tsconfig.json"
        ];
        comment-token = "//";
        lsp = {
          name = "typescript-language-server";
          args = ["--stdio"];
        };
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "a.ts"
          ];
        };
      }
      {
        name = "javascript";
        scope = "source.js";
        file-types = [
          "js"
          "mjs"
          "jsx"
        ];
        roots = [
          "package.json"
          "jsconfig.json"
        ];
        comment-token = "//";
        lsp = {
          name = "typescript-language-server";
          args = ["--stdio"];
        };
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "a.js"
          ];
        };
      }
      {
        name = "json";
        scope = "source.json";
        file-types = [
          "json"
          "jsonc"
        ];
        lsp = {
          name = "vscode-json-language-server";
          args = ["--stdio"];
        };
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "a.json"
          ];
        };
      }
      {
        name = "html";
        scope = "text.html.basic";
        lsp = {
          name = "vscode-html-language-server";
          args = ["--stdio"];
        };
        formatter = {
          command = "biome"; # Biome is adding HTML support
          args = [
            "format"
            "--stdin-file-path"
            "a.html"
          ];
        };
      }
      {
        name = "css";
        scope = "source.css";
        lsp = {
          name = "vscode-css-language-server";
          args = ["--stdio"];
        };
        formatter = {
          command = "biome";
          args = [
            "format"
            "--stdin-file-path"
            "a.css"
          ];
        };
      }
      {
        name = "svelte";
        scope = "source.svelte";
        injection-regex = "svelte";
        file-types = ["svelte"];
        comment-token = "//";
        block-comment-tokens = {
          start = "/*";
          end = "*/";
        };
        lsp = {
          name = "svelteserver";
          args = ["--stdio"];
        };
        formatter = {
          command = "prettier";
          args = [
            "--plugin"
            "prettier-plugin-svelte"
            "--parser"
            "svelte"
          ];
        };
      }
    ];
    extraPackages = pkgs:
      with pkgs; [
        typescript-language-server
        vscode-langservers-extracted
        svelte-language-server
        biome
        nodePackages.prettier
        nodejs
        bun
        deno
      ];
  };
}
