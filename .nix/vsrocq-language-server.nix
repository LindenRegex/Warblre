# Based on
# https://github.com/NixOS/nixpkgs/blob/nixos-25.11/pkgs/development/rocq-modules/vsrocq-language-server/default.nix

{
  metaFetch,
  coq_9_1,
  rocq-core_9_1,
  lib,
  glib,
  adwaita-icon-theme,
  wrapGAppsHook3,
  fetchFromGitHub,
}:

let
  ocamlPackages = rocq-core_9_1.ocamlPackages;

  repo = fetchFromGitHub {
    owner = "rocq-prover";
    repo = "vsrocq";
    rev = "v2.3.4";
    hash = "sha256-v1hQjE8U1o2VYOlUjH0seIsNG+NrMNZ8ixt4bQNyGvI=";
  };
in
ocamlPackages.buildDunePackage {
  pname = "vsrocq-language-server";
  version = "2.3.4";
  src = "${repo}/language-server";
  nativeBuildInputs = [ coq_9_1 ];
  buildInputs = [
    coq_9_1
    glib
    adwaita-icon-theme
    wrapGAppsHook3
  ]
  ++ (with ocamlPackages; [
    findlib
    lablgtk3-sourceview3
    yojson
    zarith
    ppx_inline_test
    ppx_assert
    ppx_sexp_conv
    ppx_deriving
    ppx_import
    sexplib
    ppx_yojson_conv
    lsp
    sel
    ppx_optcomp
  ]);
  preBuild = ''
    make dune-files
  '';

  meta =
    with lib;
    {
      description = "Language server for the vsrocq vscode/codium extension";
      homepage = "https://github.com/rocq-prover/vsrocq";
      maintainers = with maintainers; [ cohencyril ];
      license = licenses.mit;
    };
}