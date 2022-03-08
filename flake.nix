{
  description = "OHDSI GIS data packages";

  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = nixpkgs.lib.platforms.all;
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in {
      legacyPackages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
          import ./. { inherit pkgs; }
      );
    };

}
