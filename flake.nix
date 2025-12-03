{
  description = "A mechanization of the specification of ECMAScript regexes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    spec-merger = {
      url = "github:Ef55/SpecMerger/38ac474cca1788ec4fb4d85ecaaa8c81aecf41f6?dir=.nix";
      # inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, spec-merger, flake-utils }@input:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        oPkgs = pkgs.ocaml-ng.ocamlPackages_4_14;

        spec-diff = pkgs.writeShellApplication {
          name = "spec-diff";
          runtimeInputs = with pkgs; [
            spec-merger.packages.${system}.spec-merger
          ];
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
                (rocqPackages_9_1.callPackage .nix/vsrocq-language-server.nix {})
                
                # TODO: switch back to the packages in nixpkgs once the features we need get released
                oPkgs.ocaml
                (oPkgs.callPackage .nix/dune.nix {})
                oPkgs.ocamlformat
                oPkgs.ocaml-lsp
                oPkgs.findlib
                oPkgs.integers
                oPkgs.uucp
                oPkgs.ppx_expect
                oPkgs.melange
                oPkgs.zarith

                # coqPackages.serapi
                # python311Packages.alectryon
                spec-merger.packages.${system}.spec-merger
                spec-diff

                nodejs_24
                nodePackages.webpack-cli
              ];
          };
        };
      });
}
