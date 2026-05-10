{inputs, ...}: {
  flake.homeModules.agenix = {
    imports = [inputs.agenix.homeManagerModules.default];
  };
}
