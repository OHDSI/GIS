{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

pkgs.dockerTools.buildImage {
  name = "gis_loader";
  tag = "latest";

  contents = [
    pkgs.bashInteractive
    pkgs.cacert
    pkgs.coreutils
    pkgs.curl
    pkgs.gdal
    pkgs.gnused
    pkgs.postgis
    pkgs.postgresql_13
    pkgs.unzip
    pkgs.wget
    (pkgs.rWrapper.override{
      packages = with pkgs.rPackages; [
        # Additions for OMOP
        DatabaseConnector
        readr
        # Additions for EPA
        DBI
        RPostgreSQL
        jsonlite
        httr
      ];
    })
  ];

  config = {
    Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
  };
}
