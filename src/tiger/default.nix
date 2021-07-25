{ fetchzip
, lib
, linkFarmFromDrvs
} :
let
  sourceFiles = import ./source-files.nix;
  fetchSourceFile = sourceFile:
    fetchzip {
      name = "${sourceFile.pname}-${sourceFile.version}";
      stripRoot = false;
      url = sourceFile.url;
      sha256 = sourceFile.sha256;

      passthru =
        if lib.toInt sourceFile.year <= 2014 then {encoding = "LATIN1";} else {} //
        (removeAttrs sourceFile ["pname" "version" "url" "sha256"]);
    };
  drvs = builtins.mapAttrs (name: fetchSourceFile) sourceFiles;
in
(linkFarmFromDrvs
   "tiger-0.1"
   (builtins.attrValues drvs)
).overrideAttrs (oldAttrs: {
  meta = with lib; {
    description = "Mapping files from the US Census Bureau Geography program";
    longDescription =
      ''The TIGER/Line Shapefiles are extracts of selected geographic and
        cartographic information from the Census Bureau's Master Address File
        (MAF)/Topologically Integrated Geographic Encoding and Referencing
        (TIGER) Database (MTDB). The shapefiles include information for the
        fifty states, the District of Columbia, Puerto Rico, and the Island
        areas (American Samoa, the Commonwealth of the Northern Mariana Islands,
        Guam, and the United States Virgin Islands). The shapefiles include
        polygon boundaries of geographic areas and features, linear features
        including roads and hydrography, and point features.

        TIGER/Line is a registered trademark of the Census Bureau. TIGER/Line
        cannot be used as or within the proprietary product names of any
        commercial product including or otherwise relevant to Census Bureau data
        and may only be used to refer to the nature of such a product.
      '';
      homepage = "https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html";
      license = licenses.publicDomain;
      platforms = platforms.all;
  };
  passthru = drvs;
})
