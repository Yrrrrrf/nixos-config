# src/home/packages/dev/lang/yaml.nix
{config, ...}: {
  config.flake.lib.dev.langs.yaml = {
    helix = config.flake.lib.helix.mkLangs {
      name = "yaml";
      scope = "source.yaml";
      file-types = [
        "yml"
        "yaml"
      ];
      formatter = {
        command = "dprint";
        args = [
          "fmt"
          "--stdin"
          "yaml"
        ];
      };
    };
    extraPackages = pkgs: [pkgs.dprint];
  };
}
