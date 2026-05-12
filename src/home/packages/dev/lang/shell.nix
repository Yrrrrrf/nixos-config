{...}: {
  flake.homeModules."dev-lang-shell" = {pkgs, ...}: {
    programs.helix.languages.language = [
      {
        name = "bash";
        scope = "source.bash";
        file-types = [
          "sh"
          "bash"
          "zsh"
        ];
        shebangs = [
          "sh"
          "bash"
          "dash"
          "zsh"
        ];
        comment-token = "#";
        language-servers = ["bash-language-server"];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
        formatter = {
          command = "shfmt";
        };
        auto-format = false;
      }
    ];
    programs.helix.languages.language-server.bash-language-server = {
      command = "bash-language-server";
      args = ["start"];
    };
    home.packages = with pkgs; [
      bash-language-server
      shfmt
    ];
  };
}
