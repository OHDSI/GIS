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
      extension = "zip";

      passthru = sourceFile;

      netrcImpureEnvVars = [ "ADI_EMAIL" "ADI_PASSWORD"];
      netrcPhase = ''
        if [[ -z "$ADI_EMAIL" || -z "$ADI_PASSWORD" ]]
        then
          echo 'Environment variable ADI_EMAIL and ADI_PASSWORD are required, exiting'
          exit 1
        fi

        echo "getting login CSRF"

        CSRF=$(curl -sS --insecure -b cookies -c cookies https://www.neighborhoodatlas.medicine.wisc.edu/login |
          grep -m 1 csrf |
          sed -nr 's/(.*value.*")(.*)(".*)/\2/p')

        echo "peforming UW ADI site login"
        echo '_csrf='$CSRF'&email='$ADI_EMAIL'&password='$ADI_PASSWORD

        curl --insecure -b cookies -c cookies -X POST -d '_csrf='$CSRF'&email='$ADI_EMAIL'&password='$ADI_PASSWORD https://www.neighborhoodatlas.medicine.wisc.edu/login

        echo "getting download csrf"
        CSRF=$(curl -sS --insecure -b cookies -c cookies https://www.neighborhoodatlas.medicine.wisc.edu/download |
          grep -m 1 csrf |
          sed -nr 's/(.*value.*")(.*)(".*)/\2/p')

        curlOpts='-b cookies -c cookies -X POST -d state-type=${sourceFile.extraAttrs.state-type}&_csrf='$CSRF'&scale-group=${sourceFile.extraAttrs.scale-group}&state-name=${sourceFile.extraAttrs.state-name}&version-group=${sourceFile.extraAttrs.version-group}';

        #curl --output - --insecure -b cookies -c cookies -X POST -d '_csrf='$CSRF'&scale-group=national&state-name=AL&version-group=19' https://www.neighborhoodatlas.medicine.wisc.edu/adi-download
      '';
    };
  drvs = map fetchSourceFile sourceFiles;
in
(linkFarmFromDrvs
  "adi-3.1"
  drvs
).overrideAttrs (oldAttrs: {
  meta = with lib; {
    description = "Area Deprivation Index";
    longDescription =
      ''The Area Deprivation Index (ADI) is based on a measure created by the
        Health Resources & Services Administration (HRSA) over three decades
        ago, and has since been refined, adapted, and validated to the Census
        Block Group neighborhood level by Amy Kind, MD, PhD and her research
        team at the University of Wisconsin-Madison. It allows for rankings of
        neighborhoods by socioeconomic disadvantage in a region of interest
        (e.g. at the state or national level). It includes factors for the
        theoretical domains of income, education, employment, and housing
        quality. It can be used to inform health delivery and policy, especially
        for the most disadvantaged neighborhood groups. 
      '';
    homepage = "https://www.neighborhoodatlas.medicine.wisc.edu/";
    platforms = platforms.all;
  };
  passthru = builtins.listToAttrs (map (drv: {name = drv.name; value = drv;}) drvs);
})
