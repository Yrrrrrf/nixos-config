{...}: {
  flake.homeModules.fastfetch = {pkgs, ...}: {
    xdg.configFile."fastfetch/config.jsonc".text = ''
      {
        "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
        "logo": {
          "source": "nixos",
          "padding": { "top": 1 }
        },
        "modules": [
          "break",
          { "type": "host", "key": " PC", "keyColor": "green" },
          { "type": "cpu", "key": "│ ├", "keyColor": "green" },
          { "type": "gpu", "key": "│ ├", "keyColor": "green" },
          { "type": "display", "key": "│ ├󰍹", "keyColor": "green" },
          { "type": "disk", "key": "│ ├󰋊", "keyColor": "green" },
          { "type": "battery", "key": "└ └", "keyColor": "green" },
          "break",
          { "type": "os", "key": " OS", "keyColor": "blue" },
          { "type": "kernel", "key": "│ ├", "keyColor": "blue" },
          { "type": "wm", "key": "│ ├", "keyColor": "blue" },
          { "type": "localip", "key": "│ ├󰩟", "keyColor": "blue" },
          { "type": "custom", "key": "└ └󱄅 Gen", "command": "readlink /nix/var/nix/profiles/system | cut -d- -f2", "keyColor": "blue" },
          "break",
          { "type": "terminal", "key": " Session", "keyColor": "cyan" },
          { "type": "shell", "key": "│ ├", "keyColor": "cyan" },
          { "type": "packages", "key": "│ ├󰏖", "keyColor": "cyan" },
          { "type": "memory", "key": "└ └", "keyColor": "cyan" },
          "break",
          { "type": "uptime", "key": "󱫐 ", "keyColor": "magenta" }
        ]
      }
    '';
  };
}
