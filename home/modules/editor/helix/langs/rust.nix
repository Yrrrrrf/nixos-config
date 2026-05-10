{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "rust";
      scope = "source.rust";
      injection-regex = "rs|rust";
      file-types = ["rs"];
      roots = [
        "Cargo.toml"
        "Cargo.lock"
      ];
      auto-format = false;
      comment-tokens = [
        "//"
        "///"
        "//!"
      ];
      language-servers = ["rust-analyzer"];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      formatter = {command = "rustfmt";};
    }
  ];
  programs.helix.languages.language-server.rust-analyzer = {
    command = "rust-analyzer";
  };
  home.packages = with pkgs; [
    (lib.hiPrio rust-analyzer)
    (lib.hiPrio rustfmt)
  ];
}
