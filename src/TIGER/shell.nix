{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.haskellPackages.ghcWithPackages (ps: [
    ]))
    pkgs.unzip
    (pkgs.postgresql_13.withPackages (p: [p.postgis]))
    pkgs.gdal
  ];
}
