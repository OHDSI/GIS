{ sources ? import ../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } :

let
  sourceFiles = import ./sourceFiles.nix;

  mkShpDerivation = { name, src, schema_base_name }:
    pkgs.stdenv.mkDerivation {
      inherit name src;
      nativeBuildInputs = [
        pkgs.gdal
        (pkgs.postgresql_13.withPackages (p: [p.postgis]))
      ];

      buildPhase = ''
        EPSG=$(gdalsrsinfo -V -e -o epsg ./ | sed -n 's/.*EPSG:\(.*\)/\1/p')

        SHAPEFILES=*.shp
        mkdir build
        for shapefile in $SHAPEFILES
        do
          shp2pgsql -s $EPSG -D -- $shapefile ${schema_base_name}_stage.${name} >> ./build/${name}.sql
        done
      '';

      installPhase = ''
        mv ./build $out
      '';
    };

    mkSVIDerivation = name:
    let
      sourceFile = pkgs.lib.getAttrFromPath [name] sourceFiles;
    in
    mkShpDerivation {
      inherit name;
      schema_base_name = "svi";
      src = pkgs.fetchzip {
        inherit name;
        url = sourceFile.url;
        sha256 = sourceFile.sha256;
      };
    };
in
(map mkSVIDerivation (pkgs.lib.attrNames sourceFiles))
