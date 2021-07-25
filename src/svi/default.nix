{ fetchzip
, lib
, linkFarmFromDrvs
}:
let
  sourceFiles = import ./source-files.nix;
  fetchSourceFile = sourceFile:
    fetchzip {
      name = "${sourceFile.pname}-${sourceFile.version}";
      stripRoot = false;
      url = sourceFile.url;
      sha256 = sourceFile.sha256;

      passthru = removeAttrs sourceFile ["pname" "version" "url" "sha256"];
    };
  drvs = builtins.mapAttrs (name: fetchSourceFile) sourceFiles;
in
(linkFarmFromDrvs
   "svi-0.1"
   (builtins.attrValues drvs)
).overrideAttrs (oldAttrs: {
  meta = with lib; {
    description = "CDC/ATSDR Social Vulnerability Index";
    longDescription =
      ''The CDC/ATSDR SVI uses U.S. Census data to determine the social
        vulnerability of every census tract. Census tracts are subdivisions
        of counties for which the Census collects statistical data. The
        CDC/ATSDR SVI ranks each tract on 15 social factors, including
        poverty, lack of vehicle access, and crowded housing, and groups
        them into four related themes. Each tract receives a separate
        ranking for each of the four themes, as well as an overall ranking.
      '';
    homepage = "https://www.atsdr.cdc.gov/placeandhealth/svi/index.html";
    license = licenses.publicDomain;
    platforms = platforms.all;
  };
  passthru = drvs;
})
