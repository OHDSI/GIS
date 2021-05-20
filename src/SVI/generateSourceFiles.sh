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
  write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_DATA/SVI${year}_US.zip SVI_${year}_US
  for state in $states
  do
    write_source https://svi.cdc.gov/Documents/Data/${year}_SVI_DATA/States/${state}.zip SVI_${year}_${state}
  done
done

echo ]
