{lib, ...}: {
  name,
  language ? [], # attrset or list of attrsets, becomes one entry in programs.helix.languages.language
  servers ? {}, # { rust-analyzer = { command = "rust-analyzer"; }; }
  extraPackages ? (_: []), # pkgs: [...]
}: {
  flake.homeModules."dev-lang-${name}" = {pkgs, ...}: {
    programs.helix.languages = {
      language = if builtins.isList language then language else [language];
      language-server = servers;
    };
    home.packages = extraPackages pkgs;
  };
}
