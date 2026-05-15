{inputs, ...}: {
  flake.homeModules.common = {
    pkgs,
    config,
    lib,
    inputs,
    ...
  }: let
    user = inputs.self.lib.users.yrrrrrf;
    cli = inputs.self.lib.pkgsets.cli;
  in {
    home.username = user.username;
    home.homeDirectory = user.homeDirectory;
    home.stateVersion = "25.11";
    home.sessionPath = ["${config.home.homeDirectory}/.local/bin"];

    programs.git = {
      enable = true;
      settings = {
        user.name = user.fullName;
        user.email = user.email;
        init.defaultBranch = "main";
      };
    };

    imports = [
      inputs.self.homeModules.desktop
      inputs.self.homeModules.shell
    ];

    home.packages = cli.core pkgs;

    xdg.desktopEntries = {
      "brave-browser" = {
        name = "Brave Web Browser";
        genericName = "Web Browser";
        exec = "brave --enable-features=TouchpadOverscrollHistoryNavigation --ozone-platform-hint=auto %U";
        terminal = false;
        type = "Application";
        icon = "brave-browser";
        categories = [
          "Network"
          "WebBrowser"
        ];
      };
      "obsidian" = {
        name = "Obsidian";
        exec = "obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland %U";
        terminal = false;
        type = "Application";
      };
    };
  };
}
