{ gdal
, linkFarmFromDrvs
, postgresql_13
, stdenv
, tiger 
}:
let
  baseDrvs = tiger.passthru;
  schemaBaseName = "tiger";
  transformDrv = baseDrv:
    stdenv.mkDerivation rec {
      name = baseDrv.name;

      src = baseDrv;

      nativeBuildInputs = [
        gdal
        (postgresql_13.withPackages (p: [p.postgis]))
      ];

      installPhase = ''
        EPSG=$(gdalsrsinfo -V -e -o epsg ./ | sed -n 's/.*EPSG:\(.*\)/\1/p')
        ENCODING=${baseDrv.encoding or ""}
        if [ "$ENCODING" == "" ]
        then
          ENCODING=$(cat *.cpg)
        fi
        if [ "$ENCODING" == "" ]
        then
          ENCODING="UTF-8"
        fi
        SHAPEFILES=*.shp
        mkdir $out
        for shapefile in $SHAPEFILES
        do
          shp2pgsql -s $EPSG -D -W $ENCODING -- $shapefile ${schemaBaseName}_stage.${name} >> $out/${name}.sql
        done
      '';

      passthru = baseDrv.passthru;
    }
  ;
  drvs = builtins.mapAttrs (name: transformDrv) baseDrvs;
in
(linkFarmFromDrvs
  "tiger-pg-0.1"
  (builtins.attrValues drvs)
).overrideAttrs (oldAttrs: {
  meta = oldAttrs.meta or {} // (with tiger.meta; {
    inherit description longDescription homepage license platforms;
  });
  passthru = drvs;
})
