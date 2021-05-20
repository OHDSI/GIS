{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

let
  sourceFiles = import ./sourceFiles.nix;
in
pkgs.stdenv.mkDerivation {
  name = "SVI";

  srcs = map pkgs.fetchzip (map ( source: source // {stripRoot = false;} ) sourceFiles);

  # --------------------------------------------------------------------------
  # this is kinda hacky, maybe just rewrite unpackPhase instead of doing this?
  sourceRoot = "source";

  preUnpack = ''
    mkdir source
    cd source
    mkdir source
  '';

 postUnpack = ''
   cd ../
 '';
 # --------------------------------------------------------------------------

  buildPhase = ''
    pwd
    ls -laR ../
  '';

}
