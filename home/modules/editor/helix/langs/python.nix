{ pkgs, ... }:
{
  programs.helix.languages.language = [
    {
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
    }
  ];
  programs.helix.languages.language-server.ty = {
    command = "ty";
    args = [ "server" ];
  };
  programs.helix.languages.language-server.ruff = {
    command = "ruff";
    args = [ "server" ];
  };
  home.packages = with pkgs; [
    ty
    ruff
  ];
}
