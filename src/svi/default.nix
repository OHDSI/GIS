{ fetchzip ? (import (import ../../niv/sources.nix).nixpkgs { }).fetchzip
, lib ? (import (import ../../niv/sources.nix).nixpkgs { }).lib
, linkFarmFromDrvs ? (import (import ../../niv/sources.nix).nixpkgs { }).linkFarmFromDrvs
}:
let
  sourceFiles = builtins.fromJSON (builtins.readFile ./source-files.json);
  fetchSourceFile = sourceFile:
    fetchzip {
      name = sourceFile.name;
      stripRoot = false;
      url = sourceFile.extraAttrs.url;
      hash = sourceFile.hash;

      passthru = sourceFile;
    };
  drvs = map fetchSourceFile sourceFiles;
in
(linkFarmFromDrvs
   "svi-0.1"
   drvs
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
  passthru = builtins.listToAttrs (map (drv: {name = drv.name; value = drv;}) drvs);
})
