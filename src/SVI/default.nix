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
    rmdir source
    cd ../
  '';
  # --------------------------------------------------------------------------

  nativeBuildInputs = [
    pkgs.gdal
    pkgs.postgis
    pkgs.postgresql_13
  ];

  buildPhase = ''
    mkdir -p $out
    for dir in ./*
    do
      EPSG=$(gdalsrsinfo -V -e -o epsg $dir | sed -n 's/.*EPSG:\(.*\)/\1/p')
      SHAPEFILES=$(echo $dir/*.shp | sed 's/\.shp//g')
      for shapefile in $SHAPEFILES
      do
        shp2pgsql -s $EPSG -I $shapefile.shp > $out/$(basename $dir)_$(basename $shapefile)
      done
    done
  '';

  installPhase = ''
    echo install
  '';

}
