{config, ...}: {
  config.flake.lib.dev.langs.surql = {
    helix = config.flake.lib.helix.mkLangs {
      name = "surrealql";
      grammar = "sql";
      scope = "source.sql";
      file-types = ["surql" "surrealql"];
      comment-token = "--";
      block-comment-tokens = {
        start = "/*";
        end = "*/";
      };
      highlights = ''
        ; inherits: sql

        ((identifier) @keyword
          (#match? @keyword "(?i)^(DEFINE|SCHEMAFULL|SCHEMALESS|RELATE|TYPE|FLEXIBLE|PERMISSIONS|EVENT|OVERWRITE|UPSERT)$"))

        ((identifier) @function.builtin
          (#match? @function.builtin "(?i)^(count|rand|time::|crypto::|string::|array::|math::)"))
      '';
      lsp = {
        name = "surrealql-language-server";
        command = "surrealql-language-server";
        args = ["--stdio"];
      };
    };
    extraPackages = pkgs: let
      surrealql-ls = pkgs.stdenv.mkDerivation {
        pname = "surrealql-language-server";
        version = "0.6.0";
        src = pkgs.fetchurl {
          url = "https://github.com/surrealdb/surrealql-language-server/releases/download/v0.6.0/surrealql-language-server-linux-amd64";
          sha256 = "1a00pv544dngpix25nmyvpk9ik5cbygkdzp088rfhb8a4cdhnii7";
        };
        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [pkgs.stdenv.cc.cc.lib];
        dontUnpack = true;
        installPhase = ''
          install -D -m 755 $src $out/bin/surrealql-language-server
        '';
      };

      surrealdb-3_3 = pkgs.stdenv.mkDerivation {
        pname = "surrealdb";
        version = "3.3.0";
        src = pkgs.fetchurl {
          url = "https://github.com/surrealdb/surrealdb/releases/download/v3.3.0/surreal-v3.3.0.linux-amd64.tgz";
          sha256 = "sha256-RK6rVl9+fjnS0L8Fg8iq5ki6vJE3PHCyZYKI2Vu7zVU=";
        };
        nativeBuildInputs = [pkgs.autoPatchelfHook];
        buildInputs = [pkgs.stdenv.cc.cc.lib];
        sourceRoot = ".";
        installPhase = ''
          install -D -m 755 surreal $out/bin/surreal
        '';
      };
    in [
      surrealdb-3_3
      surrealql-ls
    ];
  };
}
