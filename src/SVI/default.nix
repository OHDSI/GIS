{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

let
  sourceFiles = import ./sourceFiles.nix;
in
pkgs.stdenv.mkDerivation {
  name = "SVI";

  srcs = map pkgs.fetchzip (map ( source: source // {stripRoot = false;} ) sourceFiles);

  buildPhase = ''
    echo hi
  '';

}
