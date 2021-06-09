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
        #[_, year, state, geom]
        nameSplit = pkgs.lib.splitString "_" n;
        year = pkgs.lib.toInt (pkgs.lib.elemAt nameSplit 1);
        geom = pkgs.lib.elemAt nameSplit 3;
      in
        !(year < 2015 && geom == "aitsn")
    )
    sourceFiles
  )
