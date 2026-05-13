{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "web";
  language = [
    {
      name = "typescript";
      language-servers = ["typescript-language-server"];
      scope = "source.ts";
      file-types = ["ts" "tsx"];
      roots = ["package.json" "tsconfig.json"];
      comment-token = "//";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "biome";
        args = ["format" "--stdin-file-path" "a.ts"];
      };
      auto-format = false;
    }
    {
      name = "javascript";
      language-servers = ["typescript-language-server"];
      scope = "source.js";
      file-types = ["js" "mjs" "jsx"];
      roots = ["package.json" "jsconfig.json"];
      comment-token = "//";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "biome";
        args = ["format" "--stdin-file-path" "a.js"];
      };
      auto-format = false;
    }
    {
      name = "json";
      scope = "source.json";
      file-types = ["json" "jsonc"];
      language-servers = ["vscode-json-language-server"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "biome";
        args = ["format" "--stdin-file-path" "a.json"];
      };
      auto-format = false;
    }
    {
      name = "html";
      scope = "text.html.basic";
      language-servers = ["vscode-html-language-server"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "prettier";
        args = ["--parser" "html"];
      };
      auto-format = false;
    }
    {
      name = "css";
      scope = "source.css";
      language-servers = ["vscode-css-language-server"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "biome";
        args = ["format" "--stdin-file-path" "a.css"];
      };
      auto-format = false;
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
      language-servers = ["svelteserver"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {
        command = "prettier";
        args = ["--plugin" "prettier-plugin-svelte" "--parser" "svelte"];
      };
      auto-format = false;
    }
  ];
  servers = {
    typescript-language-server = {
      command = "typescript-language-server";
      args = ["--stdio"];
    };
    vscode-json-language-server = {
      command = "vscode-json-language-server";
      args = ["--stdio"];
    };
    vscode-html-language-server = {
      command = "vscode-html-language-server";
      args = ["--stdio"];
    };
    vscode-css-language-server = {
      command = "vscode-css-language-server";
      args = ["--stdio"];
    };
    svelteserver = {
      command = "svelteserver";
      args = ["--stdio"];
    };
  };
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
}
