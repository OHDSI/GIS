{ sources ? import ./nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

pkgs.dockerTools.buildImage {
  name = "gis_loader";
  tag = "latest";

  contents = [
    pkgs.bashInteractive
    pkgs.cacert
    pkgs.coreutils
    pkgs.gdal
    pkgs.gnused
    pkgs.postgis
    pkgs.postgresql_13
    pkgs.unzip
    pkgs.wget
  ];

  config = {
    Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
  };
}
