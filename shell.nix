{ sources ? import ./niv/sources.nix
, pkgs ? import sources.nixpkgs {} } :
pkgs.mkShell {
  nativeBuildInputs = [
    (pkgs.haskellPackages.ghcWithPackages (ps: [
      ps.aeson
      ps.aeson-pretty
      ps.http-conduit
    ]))
    pkgs.niv
    pkgs.nix-prefetch
    pkgs.unzip
  ];
}
