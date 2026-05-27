{
  lib,
  inputs,
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
    resolveModule = m:
      if builtins.isString m
      then inputs.self.nixosModules.${m} or (throw "mkHost: unknown nixosModule '${m}' — check host.modules list")
      else m;
    user = config.flake.lib.users.${host.user} or (throw "mkHost: unknown user '${host.user}'");
  in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (host) system;
      specialArgs = {inherit inputs user;};
      modules =
        [
          # NOTE: `host` module is implicitly included here. All other modules
          # flow through host.modules as strings. This is intentional — omitting
          # "host" from every host record would be error-prone. Be aware if you
          # ever need to override or replace the host glue module per-machine.
          {_module.args.host = host;}
          inputs.self.nixosModules.host
          host.hardwareConfig
          host.hardwareModule
        ]
        ++ (map resolveModule host.modules);
    };

  config.flake.nixosModules.host = {
    lib,
    pkgs,
    inputs,
    host,
    user,
    ...
  }: {
    # DANGER: this `imports` line is evaluated during config resolution.
    # `inputs` is safe here (specialArgs). `host` is NOT safe (_module.args).
    # Conditional imports based on host.* belong in a child module, not here.
    imports = [inputs.home-manager.nixosModules.home-manager];

    networking.hostName = host.hostname;

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
    nixpkgs.config.allowUnfree = true;
    system.stateVersion = host.stateVersion or "26.05";

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
    home-manager.extraSpecialArgs = {inherit inputs user;};
    home-manager.users.${user.username} = {
      imports = [inputs.self.homeModules.default] ++ lib.optional (host ? homeExtras) host.homeExtras;
    };
  };
}
