{ nixpkgs ? (import <nixpkgs> {}).fetchFromGitHub {
    owner  = "NixOS";
    repo   = "nixpkgs";
    rev    = "afe9649210cace6d3ee9046684d4ea27dc4fd15d";
    sha256 = "19w9cvf8kn369liz3yxab4kam1pbqgn5zlry3832g29w82jwpz2l";
  }}:

with import nixpkgs {};

stdenv.mkDerivation rec {
  name = "mixco-dev";
  buildInputs = [
    nodejs-8_x
  ];
  shellHook = ''
    export REPO_ROOT=`dirname ${toString ./shell.nix}`
    addToSearchPath PATH "$REPO_ROOT"/node_modules/.bin
  '';
}
