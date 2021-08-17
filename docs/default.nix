{ sources ? import ../niv/sources.nix
, pkgs ? import sources.nixpkgs {} }:

let match-nix = import (builtins.fetchGit {
  url = "https://github.com/DavHau/mach-nix.git";
  ref = "refs/tags/3.2.0";
}) {};
in
pkgs.stdenv.mkDerivation {
  name = "ohdis_gis_docs";

  src = pkgs.lib.cleanSource ./.;

  buildPhase = ''
    make html
  '';

  installPhase = ''
    mkdir -p $out
    cp -r _build/html $out/
  '';

  buildInputs = [
    (match-nix.mkPython {
      requirements = ''
        sphinx
        myst-parser
      '';
    })
  ];
}
