{ sources ? import ../nix/sources.nix
, pkgs ? import sources.nixpkgs {} }:

let match-nix = import (builtins.fetchGit {
  url = "https://github.com/DavHau/mach-nix.git";
  ref = "refs/tags/3.2.0";
}) {};
in
pkgs.mkShell {
  nativeBuildInputs = [
    (match-nix.mkPython {
      requirements = ''
        sphinx
        myst-parser
      '';
    })
  ];
}
