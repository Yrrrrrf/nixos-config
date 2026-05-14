{
  lib,
  config,
  ...
}: {
  options.flake.lib.hosts = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = {};
  };

  options.flake.lib.mkHost = lib.mkOption {
    type = lib.types.raw;
    default = null;
  };

  config.flake.lib.mkHost = host: let
    inputs = host._inputs;
    resolveModule = m:
      if builtins.isString m
      then inputs.self.nixosModules.${m}
      else m;
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;
      specialArgs = {inherit inputs;};
      modules =
        [
          {_module.args.host = host;}
          inputs.self.nixosModules.host
          host.hardwareConfig
          host.hardwareModule
        ]
        ++ (map resolveModule host.modules);
    };

  config.flake.nixosModules.host = {
    config,
    lib,
    pkgs,
    inputs,
    host,
    ...
  }: let
    user = inputs.self.lib.users.${host.user};
  in {
    imports = [inputs.home-manager.nixosModules.home-manager];

    networking.hostName = host.hostname;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = host.stateVersion or "25.11";

    users.users.${user.username} = {
      isNormalUser = true;
      description = user.username;
      extraGroups = [
        "wheel"
        "input"
      ];
      shell = pkgs.nushell;
      ignoreShellProgramCheck = true;
    };

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = {inherit inputs;};
    home-manager.users.${user.username} = {
      imports = [inputs.self.homeModules.default] ++ lib.optional (host ? homeExtras) host.homeExtras;
    };
  };
}
