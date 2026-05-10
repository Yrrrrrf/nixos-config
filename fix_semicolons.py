import os
from pathlib import Path

for d, dirs, files in os.walk('src/home'):
    for f in files:
        if f.endswith('.nix') and f != 'placeholder.nix':
            p = Path(d) / f
            content = p.read_text()
            if content.endswith('\n}\n'):
                # Check if it lacks a semicolon before the newline
                lines = content.split('\n')
                if len(lines) >= 3 and not lines[-3].endswith(';'):
                    lines[-3] = lines[-3] + ';'
                    p.write_text('\n'.join(lines))
