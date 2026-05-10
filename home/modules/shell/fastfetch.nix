{pkgs, ...}: {
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
        "type": "nixos",
        "padding": { "top": 2 }
      },
      "modules": [
        "break",
        { "type": "host", "key": " PC", "keyColor": "green" },
        { "type": "cpu", "key": "│ ├", "keyColor": "green" },
        { "type": "gpu", "key": "│ ├", "keyColor": "green" },
        { "type": "memory", "key": "└ └", "keyColor": "green" },
        "break",
        { "type": "os", "key": " OS", "keyColor": "blue" },
        { "type": "kernel", "key": "│ ├", "keyColor": "blue" },
        { "type": "wm", "key": "│ ├", "keyColor": "blue" },
        { "type": "shell", "key": "└ └", "keyColor": "blue" },
        "break",
        { "type": "uptime", "key": "󱫐 ", "keyColor": "magenta" }
      ]
    }
  '';
}
