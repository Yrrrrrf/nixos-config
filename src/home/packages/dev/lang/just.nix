{...}: {
  flake.homeModules."dev-lang-just" = {pkgs, ...}: {
    programs.helix.languages.language = [
      {
        name = "just";
        scope = "source.just";
        file-types = ["Justfile" "just"];
        comment-token = "#";
        language-servers = ["just-lsp"];
        indent = {
          tab-width = 4;
          unit = "    ";
        };
        formatter = {
          command = "just";
          args = ["--fmt" "--unstable"];
        };
        auto-format = false;
      }
    ];
    programs.helix.languages.language-server.just-lsp = {
      command = "just-lsp";
    };
    home.packages = with pkgs; [just-lsp just];
  };
}
