{inputs, ...}: {
  flake.homeModules.default = {inputs, ...}: {
    imports = [inputs.self.homeModules.dev];
  };
}
