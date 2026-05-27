{lib, ...}: {
  options.flake.lib.pkgsets.dev = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.pkgsets.dev = {
    build = pkgs: with pkgs; [pkg-config gcc openssl.dev];
    ides = pkgs: with pkgs; [vscode jetbrains-toolbox antigravity zed-editor];
  };

  options.flake.lib.dev.langs = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  options.flake.lib.helix = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.helix.mkLangs = specs: let
    toList = x:
      if builtins.isList x
      then x
      else [x];

    # lsp: "name" | { name; command?; args?; ... }
    normLsp = s:
      if builtins.isString s
      then {
        name = s;
        command = s;
      }
      else {command = s.name;} // s;

    # formatter: "cmd" -> { command = "cmd"; }; attrset passthrough.
    normFmt = f:
      if f == null
      then null
      else if builtins.isString f
      then {command = f;}
      else f;

    mkOne = {
      name,
      scope ? "source.${name}",
      comment-token ? null,
      lsp ? [],
      formatter ? null,
      ...
    } @ s: let
      lsps = map normLsp (toList lsp);
      fmt = normFmt formatter;
      extra = builtins.removeAttrs s [
        "name"
        "scope"
        "comment-token"
        "lsp"
        "formatter"
      ];
    in
      {
        inherit name;
        auto-format = true;
        language-servers = map (l: l.name) lsps;
      }
      // lib.optionalAttrs (scope != null) {inherit scope;}
      // lib.optionalAttrs (comment-token != null) {inherit comment-token;}
      // lib.optionalAttrs (fmt != null) {formatter = fmt;}
      // extra;

    items = toList specs;
    allLsps = lib.concatMap (s: map normLsp (toList (s.lsp or []))) items;
  in {
    language = map mkOne items;
    language-server = lib.listToAttrs (
      map (l: {
        name = l.name;
        value = builtins.removeAttrs l ["name"];
      })
      allLsps
    );
  };
}
