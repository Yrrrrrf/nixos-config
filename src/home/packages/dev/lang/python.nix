{config, ...}: {
  config.flake.lib.dev.langs.python = {
    helix = config.flake.lib.helix.mkLangs {
      name = "python";
      scope = "source.python";
      injection-regex = "py(thon)?";
      file-types = [
        "py"
        "pyi"
        "pyw"
      ];
      shebangs = [
        "python"
        "uv"
      ];
      roots = [
        "pyproject.toml"
        "setup.py"
        "poetry.lock"
        "pyrightconfig.json"
      ];
      comment-token = "#";
      lsp = [
        {
          name = "ty";
          args = ["server"];
        }
      ];
      formatter = {
        command = "ruff";
        args = [
          "format"
          "."
        ];
      };
    };
    extraPackages = pkgs:
      with pkgs; [
        uv # pkg manager
        ty # lsp
        ruff # fmt
      ];
  };
}
