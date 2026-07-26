{inputs, ...}: {
  flake.homeModules.scripts = {lib, ...}: let
    scriptFiles = lib.mapAttrs' (
      fname: _type: let
        isLib = lib.hasPrefix "_" fname;
        installName =
          if isLib
          then fname
          else lib.removeSuffix ".nu" fname;
      in
        lib.nameValuePair ".local/bin/${installName}" {
          source = ./scripts + "/${fname}";
          executable = !isLib;
        }
    ) (lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".nu" n) (builtins.readDir ./scripts));
  in {
    home.file = scriptFiles;
  };
}
