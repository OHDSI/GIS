let
  sources = import ../../niv/sources.nix;
in
{ pkgs ? import sources.nixpkgs {} }: with pkgs;
mkShell {
  nativeBuildInputs = [
    (haskellPackages.ghcWithPackages (ps: []))
    unzip
  ];
}
