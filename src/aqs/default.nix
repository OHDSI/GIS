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
   "aqs-0.1"
   drvs
).overrideAttrs (oldAttrs: {
  meta = with lib; {
    description = "EPA Air Quality System Air Data Pre-Generated Data Files";
    longDescription =
      ''The Air Quality System (AQS) contains ambient air pollution data
        collected by EPA, state, local, and tribal air pollution control
        agencies from over thousands of monitors.  AQS also contains
        meteorological data, descriptive information about each monitoring
        station (including its geographic location and its operator), and data
        quality assurance/quality control information. 
      '';
    homepage = "https://aqs.epa.gov/aqsweb/airdata/download_files.html";

    # https://www.epa.gov/outdoor-air-quality-data/do-i-need-request-permission-use-monitoring-data-and-graphics-airdata
    license = licenses.publicDomain;
    platforms = platforms.all;
  };
  passthru = builtins.listToAttrs (map (drv: {name = drv.name; value = drv;}) drvs);
})
