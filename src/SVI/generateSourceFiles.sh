#!/bin/bash

set -e

states=$(cat states)

years='2014 2016 2018'

function write_source() {
  echo '  {'
  echo '    name = "'$2'";'
  echo '    url = "'$1'";'
  echo '    sha256 = "'$(nix-prefetch-url --unpack --name $2 $1)'";'
  echo '  }'
}

echo '# Do not modify manually, generate with `sh generateSourceFiles.sh > sourceFiles.nix`'
echo [

for year in $years
do
  county_file_postfix=COUNTY
  if [ $year == 2014 ]
  then
    county_file_postfix=CNTY
  fi
  write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_DATA/SVI${year}_US.zip SVI_${year}_US_tract
  write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_Data/SVI${year}_US_${county_file_postfix}.zip SVI_${year}_US_county
  for state in $states
  do
    write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_DATA/States/${state}.zip SVI_${year}_${state}_tract
    write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_Data/States_Counties/${state}_${county_file_postfix}.zip SVI_${year}_${state}_county
  done
  # no county source in tribal tracts
  write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_DATA/States/Tribal_Tracts.zip SVI_${year}_Tribal_Tracts_tract
done

echo ]
