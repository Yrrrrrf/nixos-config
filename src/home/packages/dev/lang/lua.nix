{...}: {
  flake.homeModules."dev-lang-lua" = {pkgs, ...}: {
    programs.helix.languages.language = [
      {
        name = "lua";
        scope = "source.lua";
        file-types = ["lua"];
        comment-token = "--";
        language-servers = ["lua-language-server"];
        auto-format = true;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
        formatter = {
          command = "stylua";
          args = ["-"];
        };
      }
    ];
    programs.helix.languages.language-server.lua-language-server = {
      command = "lua-language-server";
    };
    home.packages = with pkgs; [lua-language-server stylua lua];
  };
}
