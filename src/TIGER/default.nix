{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

let
  utils = import ../common/nix/utils.nix {};
  sourceFiles = import ./sourceFiles.nix;
in
pkgs.lib.mapAttrsToList
  (utils.mkSourceFileDerivation "tiger")
  # TODO: Figure out locale error and remove filter
  (pkgs.lib.filterAttrs
    (n: v:
      let
        year = pkgs.lib.toInt v.year;
        geom = v.geom;
      in
        !(year <= 2014 && (geom == "aitsn" || geom == "cousub")
    )
    sourceFiles
  )
