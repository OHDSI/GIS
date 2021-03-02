{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

pkgs.dockerTools.buildImage {
  name = "gis_loader";
  tag = "latest";

  contents = [
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.gdal
    pkgs.gnused
    pkgs.postgis
    pkgs.postgresql_13
    pkgs.unzip
  ];
}
