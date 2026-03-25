{
  description = "A mechanization of ECMAScript specification of regexes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    spec-merger = {
      url = "github:epfl-systemf/SpecMerger/?dir=.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, spec-merger, flake-utils }@input:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        oPkgs = pkgs.rocq-core_9_1.ocamlPackages;

        spec-diff = pkgs.writeShellApplication {
          name = "spec-diff";
          runtimeInputs = with pkgs; [
            spec-merger.packages.${system}.spec-merger
          ];
          # TODO: find way to guarantee this runs from the root of this repo
          text = ''
            python3 main.py > actual_text_output.txt
            diff -y --color=always expected_text_output.txt actual_text_output.txt
          '';
        };
      in {
        devShells = {
            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                rocqPackages_9_1.rocq-core
                rocqPackages_9_1.stdlib
                (rocqPackages_9_1.callPackage ./vsrocq-language-server.nix {})

                # TODO: switch back to the packages in nixpkgs once the features we need get released
                oPkgs.ocaml
                (oPkgs.callPackage ./dune.nix {}) # Needs to be >= 3.21
                oPkgs.ocamlformat
                oPkgs.ocaml-lsp
                oPkgs.findlib
                oPkgs.integers
                oPkgs.uucp
                oPkgs.ppx_expect
                oPkgs.melange
                oPkgs.zarith

                spec-merger.packages.${system}.spec-merger
                spec-diff

                nodejs_24
                nodePackages.webpack-cli
              ];
          };
        };
      });
}
