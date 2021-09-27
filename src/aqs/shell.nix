{ sources ? import ../../niv/sources.nix
, pkgs ? import sources.nixpkgs {} } :

pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.haskellPackages.ghcWithPackages (ps: [
      ps.http-conduit
    ]))
    pkgs.unzip
  ];
}
