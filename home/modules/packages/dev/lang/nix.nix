{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "nix";
      scope = "source.nix";
      file-types = ["nix"];
      comment-token = "#";
      language-servers = ["nil"];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      formatter = {command = "alejandra";};
      auto-format = false;
    }
  ];
  programs.helix.languages.language-server.nil = {
    command = "nil";
  };
  home.packages = with pkgs; [nil alejandra];
}
