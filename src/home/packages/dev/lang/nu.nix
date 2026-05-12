{...}: {
  flake.homeModules."dev-lang-nu" = {pkgs, ...}: {
    programs.helix.languages.language = [
      {
        name = "nu";
        scope = "source.nu";
        file-types = ["nu"];
        shebangs = ["nu"];
        comment-token = "#";
        language-servers = ["nu-lsp"];
        auto-format = false;
        indent = {
          tab-width = 2;
          unit = "  ";
        };
      }
    ];
    programs.helix.languages.language-server.nu-lsp = {
      command = "nu";
      args = ["--lsp"];
    };
    home.packages = with pkgs; [nushell];
  };
}
