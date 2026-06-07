{
  description = "System performance and health test suite dependencies";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
  };

  outputs = {self, nixpkgs}: let
    supportedSystems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    devShells = forAllSystems (system: {
      default = (pkgsFor system).mkShell {
        buildInputs = with (pkgsFor system); [
          nushell
          fio
          memtester
          iw
          iperf3
          iputils
          iwd
          mesa-demos
          pciutils
          smartmontools
        ];
      };
    });
  };
}
