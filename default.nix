# This file describes your repository contents.
# It should return a set of nix derivations
# and optionally the special attributes `lib`, `modules` and `overlays`.
# It should NOT import <nixpkgs>. Instead, you should take pkgs as an argument.
# Having pkgs default to <nixpkgs> is fine though, and it lets you use short
# commands such as:
#     nix-build -A mypackage
let
  sources = import ./niv/sources.nix;
in
{ pkgs ? import sources.nixpkgs { } }:

with pkgs;

rec {

  # The `lib`, `modules`, and `overlay` names are special
  #lib = import ./nix/lib { inherit pkgs; }; # functions
  #modules = import ./modules; # NixOS modules
  #overlays = import ./src/common/nix/overlays; # nixpkgs overlays

  svi = callPackage ./src/svi { };
  svi-pg = callPackage ./src/svi/pg.nix { svi = svi; };
  tiger = callPackage ./src/tiger { };
  tiger-pg = callPackage ./src/tiger/pg.nix { tiger = tiger; };
}
