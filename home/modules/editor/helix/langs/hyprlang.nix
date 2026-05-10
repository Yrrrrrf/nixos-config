{ pkgs, ... }:
{
  programs.helix.languages.language = [{
    name = "hyprlang";
    scope = "source.hyprlang";
    file-types = ["hyprland.conf" "hyprlock.conf" "hypridle.conf" "hyprpaper.conf" { glob = "hypr/*.conf"; }];
    comment-token = "#";
    language-servers = [ "hyprlang-language-server" ];
    auto-format = false;
    indent = { tab-width = 4; unit = "    "; };
  }];
  programs.helix.languages.language-server.hyprlang-language-server = {
    command = "hyprls";
  };
  home.packages = with pkgs; [ hyprls ];
}
