# Based on
# https://github.com/NixOS/nixpkgs/blob/2375cc015c9c2d5dfaff876d063cd9218ae89a84/pkgs/development/tools/ocaml/dune/3.nix

{
  lib,
  stdenv,
  fetchurl,
  ocaml,
  findlib,
  ocaml-lsp,
  dune-release,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "dune";
  version = "3.21.0";

  src = fetchFromGitHub {
    owner = "ocaml";
    repo = "dune";
    rev = "6e9d965bb5bbadfe9cbf89314cb6f8ecaa845bd9";
    hash = "sha256-YOey/GwrJVrQwEgoV8taDF6t6LgCJtrtmPQPvAtA7EQ=";
  };

  nativeBuildInputs = [
    ocaml
    findlib
  ];

  strictDeps = true;

  buildFlags = [ "release" ];

  dontAddPrefix = true;
  dontAddStaticConfigureFlags = true;
  configurePlatforms = [ ];

  installFlags = [
    "PREFIX=${placeholder "out"}"
    "LIBDIR=$(OCAMLFIND_DESTDIR)"
  ];

  passthru.tests = {
    inherit ocaml-lsp dune-release;
  };

  meta = {
    homepage = "https://dune.build/";
    description = "Composable build system";
    mainProgram = "dune";
    changelog = "https://github.com/ocaml/dune/raw/${version}/CHANGES.md";
    maintainers = [ lib.maintainers.vbgl ];
    license = lib.licenses.mit;
    inherit (ocaml.meta) platforms;
  };
}