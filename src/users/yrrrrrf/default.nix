{lib, ...}: {
  options.flake.lib.users = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };
  config.flake.lib.users.yrrrrrf = {
    username = "yrrrrrf";
    homeDirectory = "/home/yrrrrrf";
    fullName = "Fernando Bryan Reza Campos";
    email = "fer.rezac@outlook.com";
    wallpaper = ./wallpaper.jpg;
    profileImage = ./profile.png;
    hashedPassword = "$6$w30PuhD8HJNMxx6D$wjIJOh8G8QslMq0jtqRjiStfiUNIdcR5ShRqVzTO5dRYc1ZKSTD8QaUdvnPA1OwXGUy744N.m//OcHCshpLUR/";
  };
}
