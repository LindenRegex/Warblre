{
  description = "A mechanization of the specification of ECMAScript regexes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    spec-merger = {
      url = "github:Ef55/SpecMerger/38ac474cca1788ec4fb4d85ecaaa8c81aecf41f6?dir=.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    melange = {
      url = "github:melange-re/melange/v3-414";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, spec-merger, flake-utils, melange }@input:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ melange.overlays.default ]; };
        pkgs-unstable = import nixpkgs-unstable { inherit system; };
      in {
        devShells = {
            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                coq

                ocaml
                pkgs-unstable.dune_3
                ocamlPackages.ocamlformat
                ocamlPackages.ocaml-lsp
                ocamlPackages.findlib
                ocamlPackages.integers
                ocamlPackages.uucp
                ocamlPackages.ppx_expect
                ocamlPackages.melange
                ocamlPackages.zarith

                coqPackages.serapi
                python311Packages.alectryon
                spec-merger.packages.${system}.spec-merger

                nodejs_21
                nodePackages.webpack-cli
              ];
          };
        };
      });
}
