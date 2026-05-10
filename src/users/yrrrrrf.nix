{lib, ...}: {
  options.flake.lib = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.users.yrrrrrf = {
    username = "yrrrrrf";
    homeDirectory = "/home/yrrrrrf";
    fullName = "Fernando Bryan Reza Campos";
    email = "fer.rezac@outlook.com";
  };
}
