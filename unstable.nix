{
  deno = null;
  bun = null;
  antigravity-ide = null;
  lazyrsync = null;
  tetro-tui = null;
  herdr-desktop = pkg:
    pkg.overrideAttrs {
      dontCargoUseSystemLibs = true;
      doCheck = false;
    };
  brave = null;
  vscode = null;
}
