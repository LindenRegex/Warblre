{
  description = "A mechanization of of the ECMAScript specification of regexes.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    spec-merger = {
      url = "github:epfl-systemf/SpecMerger/?dir=.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, nix-filter, spec-merger, flake-utils }@input:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        oPkgs = pkgs.rocq-core_9_1.ocamlPackages;

        # TODO: switch back to nixpkgs once 3.21 is available
        dune321 = (oPkgs.callPackage ./dune.nix {});

        maintainers = {
          nds = {
            name = "Noé De Santo";
            github = "Ef55";
            githubId = "61206225";
          };
        };

        warblre = pkgs.rocqPackages_9_1.mkRocqDerivation.override { dune = dune321; } {
          pname = "warblre";
          owner = "linden-regex";

          src = nixpkgs.lib.fileset.toSource {
            root = ./..;
            fileset = nixpkgs.lib.fileset.unions [
              ./../dune-project
              ./../warblre.opam
              ./../mechanization
            ];
          };
          version = "1.0";

          useDune = true;
          opam-name = "warblre";

          propagatedBuildInputs = with pkgs; [
            rocqPackages_9_1.stdlib
          ];

          meta = {
            description = "A Rocq mechanization of the ECMAScript specification of regexes.";
            maintainers = [
              maintainers.nds
            ];
          };
        };

        warblre-engines = oPkgs.buildDunePackage.override { dune_3 = dune321; } {
          pname = "warblre-engines";
          owner = "linden-regex";

          src = nixpkgs.lib.fileset.toSource {
            root = ./..;
            fileset = nixpkgs.lib.fileset.unions [
              ./../dune-project
              ./../warblre-engines.opam
              ./../engines
            ];
          };
          version = "1.0";

          opame-name = "warblre-engines";

          nativeBuildInputs = [
            pkgs.rocqPackages_9_1.rocq-core
            oPkgs.melange
          ];

          buildInputs = with oPkgs; [
            pkgs.rocqPackages_9_1.rocq-core
            warblre
            ocaml-lsp
            integers
            uucp
            ppx_expect
            melange
            zarith
          ];

          meta = {
            description = "A regex engine following the ECMAScript specification of regexes.";
            maintainers = [
              maintainers.nds
            ];
          };
        };

        spec-diff = pkgs.writeShellApplication {
          name = "spec-diff";
          runtimeInputs = with pkgs; [
            spec-merger.packages.${system}.spec-merger
          ];
          # TODO: fix me
          text = ''
            python3 main.py > actual_text_output.txt
            diff -y --color=always expected_text_output.txt actual_text_output.txt
          '';
        };
      in {
        devShells = {
            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                # TODO: switch back to nixpkgs once 9.1 is available
                (rocqPackages_9_1.callPackage ./vsrocq-language-server.nix {})

                oPkgs.ocamlformat
                oPkgs.ocaml-lsp
                oPkgs.findlib

                spec-merger.packages.${system}.spec-merger
                spec-diff

                nodejs_24
                nodePackages.webpack-cli
              ] ++
                warblre.propagatedBuildInputs ++
                warblre-engines.nativeBuildInputs ++
                warblre-engines.buildInputs;
          };
        };

        packages = {
          warblre = warblre;
          warblre-engines = warblre-engines;
          default = warblre;
        };
      });
}
