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
          "nu"
        ];
        shebangs = [
          "sh"
          "bash"
          "dash"
          "zsh"
          "nu"
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
      {
        name = "lua";
        scope = "source.lua";
        file-types = ["lua"];
        comment-token = "--";
        language-servers = ["lua-language-server"];
        indent = {
          tab-width = 2;
          unit = "  ";
        };
        formatter = {
          command = "stylua";
        };
        auto-format = false;
      }
    ];
    programs.helix.languages.language-server.bash-language-server = {
      command = "bash-language-server";
      args = ["start"];
    };
    programs.helix.languages.language-server.lua-language-server = {
      command = "lua-language-server";
    };
    home.packages = with pkgs; [
      bash-language-server
      shfmt
      lua-language-server
      stylua
    ];
  };
}
