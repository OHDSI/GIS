{ sources ? import ../../niv/sources.nix
, pkgs ? import sources.nixpkgs {} } :
pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.haskellPackages.ghcWithPackages (ps: [
      ps.aeson
      ps.aeson-pretty
    ]))
    pkgs.unzip
    pkgs.nix-prefetch
  ];
}
