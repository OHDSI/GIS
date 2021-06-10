{ sources ? import ../../../nix/sources.nix
, pkgs ? import sources.nixpkgs {} } : rec {

mkShpDerivation = { name, src, schema_base_name, encoding ? "" }:
  pkgs.stdenv.mkDerivation {
    inherit name src;
    nativeBuildInputs = [
      pkgs.gdal
      (pkgs.postgresql_13.withPackages (p: [p.postgis]))
    ];

    buildPhase = ''
      EPSG=$(gdalsrsinfo -V -e -o epsg ./ | sed -n 's/.*EPSG:\(.*\)/\1/p')
      ENCODING=${encoding}
      if [ "$ENCODING" == "" ]
      then
        ENCODING=$(cat *.cpg)
      fi
      if [ "$ENCODING" == "" ]
      then
        ENCODING="UTF-8"
      fi

      SHAPEFILES=*.shp
      mkdir build
      for shapefile in $SHAPEFILES
      do
        shp2pgsql -s $EPSG -D -W $ENCODING -- $shapefile ${schema_base_name}_stage.${name} >> ./build/${name}.sql
      done
    '';

    installPhase = ''
      mv ./build $out
    '';
  };

mkSourceFileDerivation = {schema_base_name, name, sourceFile, encoding ? ""}:
  mkShpDerivation {
    inherit name schema_base_name encoding;
    src = pkgs.fetchzip {
      inherit name;
      stripRoot = false;
      url = sourceFile.url;
      sha256 = sourceFile.sha256;
    };
  };

}
