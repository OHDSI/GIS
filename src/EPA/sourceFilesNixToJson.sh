#!/usr/bin/env bash
sed -e 's/\([A-Za-z0-9_]*\) =/"\1":/g; s/;/,/g' source-files.nix | sed -e ':a' -e 'N' -e '$!ba' -e $'s/,\\n\([ ]*\)}/\\\n\\1}/g' | tail -n +2 > source-files.json