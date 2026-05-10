{pkgs, ...}: {
  programs.helix.languages.language = [
    {
      name = "typst";
      language-servers = ["tinymist"];
      file-types = ["typ"];
      formatter = {
        command = "typstyle";
      };
    }
  ];
  programs.helix.languages.language-server.tinymist = {
    command = "tinymist";
  };
  home.packages = with pkgs; [
    tinymist
    typstyle
  ];
}
