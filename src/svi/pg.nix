{ gdal
, linkFarmFromDrvs
, postgresql_13
, stdenv
, svi
}:
let
  sviDrvs = svi.passthru;
  schemaBaseName = "svi";
  transformSviDrv = sviDrv:
    stdenv.mkDerivation rec {
      name = sviDrv.name;

      src = sviDrv;

      nativeBuildInputs = [
        gdal
        (postgresql_13.withPackages (p: [p.postgis]))
      ];

      installPhase = ''
        EPSG=$(gdalsrsinfo -V -e -o epsg ./ | sed -n 's/.*EPSG:\(.*\)/\1/p')
        ENCODING=${sviDrv.encoding or ""}
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

      passthru = sviDrv.passthru;
    }
  ;
  drvs = builtins.mapAttrs (name: transformSviDrv) sviDrvs;
in
(linkFarmFromDrvs
  "svi-pg-0.1"
  (builtins.attrValues drvs)
).overrideAttrs (oldAttrs: {
  meta = oldAttrs.meta or {} // (with svi.meta; {
    inherit description longDescription homepage license platforms;
  });
  passthru = drvs;
})
