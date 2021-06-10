{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

let
  utils = import ../common/nix/utils.nix {};
  sourceFiles = import ./sourceFiles.nix;
in
pkgs.lib.mapAttrsToList
  (name: sourceFile:
    utils.mkSourceFileDerivation {
      inherit name sourceFile;
      schema_base_name = "svi";
  })
  sourceFiles
