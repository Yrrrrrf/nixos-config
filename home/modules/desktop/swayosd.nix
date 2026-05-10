# /etc/nixos/home/modules/desktop/swayosd.nix
{pkgs, ...}: {
  # 1. Disable the standard module to stop it from generating the broken file
  services.swayosd.enable = false;

  # 2. Install the package manually
  home.packages = [pkgs.swayosd];

  # 3. Manually define the Systemd Service (The "Nuclear" Fix)
  systemd.user.services.swayosd-server = {
    Unit = {
      Description = "SwayOSD Service";
      Documentation = "https://github.com/ErikReider/SwayOSD";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      # We point directly to the binary in the nix store
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "always";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # 4. Your Styling (Icon-only Mic, Wide Volume)
  xdg.configFile."swayosd/style.css".text = ''
    /* --- Base Window --- */
    window {
        font-family: "JetBrainsMono Nerd Font";
        font-size: 24px;
        font-weight: bold;
        color: #cdd6f4;
        background: #1e1e2e;
        border: 2px solid #cba6f7;
        border-radius: 12px;
        padding: 10px 20px;
    }

    /* --- Common Slider (Volume/Brightness) --- */
    trough {
        background-color: #313244;
        border-radius: 10px;
        min-height: 10px;
        min-width: 250px;
    }

    progress {
        background-color: #cba6f7;
        border-radius: 10px;
        min-height: 10px;
    }

    /* --- MICROPHONE SPECIFIC (Icon Only) --- */
    window#input-volume {
        padding: 10px;
    }

    window#input-volume trough,
    window#input-volume progress {
        min-height: 0;
        min-width: 0;
        margin: 0;
        padding: 0;
        background-color: transparent;
        box-shadow: none;
        border: none;
    }

    window#input-volume image {
        margin: 0;
        padding: 5px;
        color: #cba6f7;
    }

    window#input-volume image:disabled {
        color: #f38ba8;
    }
  '';
}
