{lib, ...}:
(import ../../../../lib/mkLang.nix {inherit lib;}) {
  name = "python";
  language = {
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
    language-servers = [
      "ty"
      "ruff"
    ];
    indent = {
      tab-width = 4;
      unit = "    ";
    };
    formatter = {
      command = "ruff";
      args = [
        "format"
        "-"
      ];
    };
    auto-format = false;
  };
  servers = {
    ty = {
      command = "ty";
      args = ["server"];
    };
    ruff = {
      command = "ruff";
      args = ["server"];
    };
  };
  extraPackages = pkgs:
    with pkgs; [
      ty
      ruff
      uv
    ];
}
