{ fetchzip
, lib
, linkFarmFromDrvs
}:
let
  sourceFiles = builtins.fromJSON (builtins.readFile ./source-files.json);
  fetchSourceFile = sourceFile:
    fetchzip {
      name = "${sourceFile.pname}-${sourceFile.version}";
      stripRoot = false;
      url = sourceFile.url;
      sha256 = sourceFile.sha256;
      extension = "zip";

      passthru = removeAttrs sourceFile ["url" "sha256"];

      netrcImpureEnvVars = [ "ADI_EMAIL" "ADI_PASSWORD" ];
      netrcPhase = ''
        if [[ -z "$ADI_EMAIL" || -z "$ADI_PASSWORD" ]]
        then
          echo 'Environment variable ADI_EMAIL and ADI_PASSWORD are required, exiting'
          exit 1
        fi

        echo "getting login csrf"

        CSRF=$(curl -sS --insecure -b cookies -c cookies https://www.neighborhoodatlas.medicine.wisc.edu/login |
          grep -m 1 csrf |
          sed -nr 's/(.*value.*")(.*)(".*)/\2/p')

        echo "peforming UW ADI site login"

        curl -sS --insecure -b cookies -c cookies -X POST -d '_csrf='$CSRF'&email='$ADI_EMAIL'&password='$ADI_PASSWORD https://www.neighborhoodatlas.medicine.wisc.edu/login

        echo "getting download csrf"
        CSRF=$(curl -sS --insecure -b cookies -c cookies https://www.neighborhoodatlas.medicine.wisc.edu/download |
          grep -m 1 csrf |
          sed -nr 's/(.*value.*")(.*)(".*)/\2/p')

        curlOpts='-b cookies -c cookies -X POST -d state-type=${sourceFile.state-type}&_csrf='$CSRF'&scale-group=${sourceFile.scale-group}&state-name=${sourceFile.state-name}&version-group=${sourceFile.version-group}';

        #curl --output - --insecure -b cookies -c cookies -X POST -d '_csrf='$CSRF'&scale-group=national&state-name=AL&version-group=19' https://www.neighborhoodatlas.medicine.wisc.edu/adi-download
      '';
    };
  drvs = builtins.mapAttrs (name: fetchSourceFile) sourceFiles;
in
(linkFarmFromDrvs
  "adi-0.1"
  (builtins.attrValues drvs)
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
  passthru = drvs;
})
