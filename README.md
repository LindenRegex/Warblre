# Warblre: <br/>A Rocq Mechanization of ECMAScript Regexes

This repository contains *Warblre*, a Rocq mechanization of ECMAScript regexes.
[ECMAScript](https://ecma-international.org/publications-and-standards/standards/ecma-262/) is the specification followed by JavaScript implementations, and a mechanization of its regex semantics makes it possible to reason formally about these regexes from a proof assistant.

The mechanization has the following properties:
- **Auditable**:
    The mechanization is written in a literate style, interleaving the Gallina code with comments taken directly from the specification (e.g. [CompileSubPattern](https://262.ecma-international.org/14.0/#sec-compilesubpattern)), which allows anyone to easily check that the mechanization follows the specification.
- **Executable**:
    The mechanization can be extracted to executable OCaml (and then JavaScript) code.
    The extracted engine can hence be used as an executable ground truth.
- **Proven-safe**:
    We proved that the regex engine resulting from our mechanization always terminate and that no error (access out-of-bounds, assertion failure, ...) occurs.
- **Faithful**:
    Once combined with a JavaScript runtime, the extracted engine passes all tests related to regexes.

![A sample of the mechanization](etc/disjunction.png)
![*Curruca communis* perched on a branch](etc/cover.webp)

## Table of Contents

- [Installation](#installation)
- [Using Warblre](#using-warblre)
- [Layout of this repository](#structure-of-the-repository)
- [Understanding Warblre](#understanding-warblre)
- [License](#license)
- [Citing Warblre](#citing-warblre)

## Installation

### Using [opam](https://opam.ocaml.org/)

Add this repository as a package source:
```
opam pin add --no-action warblre https://github.com/LindenRegex/Warblre
```

### Using [nix](https://nixos.org/) (flake)

1.
    Add this repository as an input:
    ```nix
    warblre.url = "github:LindenRegex/Warblre";
    ```
2.
    Add the provided packages as dependencies:
    ```
    warblre.packages.${system}.warblre
    warblre.packages.${system}.warblre-engines
    ```

### Building from source

1.
    All of the core dependencies can be installed through [opam](https://opam.ocaml.org/):
    ```shell
    opam install . --deps-only
    ```
    This will allow you to step through the Rocq code, extract the OCaml code and compile it.
2. **[Optional]**
    In order to pack and and run the JavaScript code, you will need to install [Node.js](https://nodejs.org/en), e.g., using [nvm](https://github.com/nvm-sh/nvm).
    ```shell
    nvm install 24.13.0
    ```
    as well as some JavaScript dependencies:
    ```shell
    npm install .npm --no-save # Install packages used by our JavaScript code
    ```

Alternatively, the nix flake provides a devshell with (almost) all dependencies:
```
nix develop
# Optional: install the javascript dependencies
npm install .npm --no-save
```
## Using Warblre

Warblre provides two packages
- `warblre`: Warblre "proper", i.e., a Rocq mechanization of the ECMAScript
  specification of regexes.
- `warblre-engines`: Exectuable regex engines extracted from the Rocq
  mechanization. Two engines are provided: one for OCaml, and one for JavaScript
  (using [`melange`](https://melange.re)).

### Step-by-step usage

1.
    Add `warblre` (and/or `warblre-engines`) as a dependency in your `dune-project`/`*.opam` project file.
2.
    Depending on your language/usecase:
    - **Rocq**: Add the Warblre theory as a dependency:
      ```
      (theories ... Warblre ...)
      ```
    - **OCaml**: Add the OCaml engine as dependency:
      ```
      (libraries ... warblre-engines.ocaml)
      ```
    - **OCaml (Melange/JS)**:
      Add the JavaScript engine as dependency:
      ```
      (libraries ... warblre-engines.js)
      ```
3.
    You can use Warblre in Rocq/OCaml by importing it:
    ```ocaml
    (* OCaml *)
    open Warblre.Engines
    ```
    ```coq
    (* Rocq *)
    From Warblre Require Import Semantics.
    ```
    See the examples ([Rocq](/home/noe/Code/Warblre/Warblre/examples/rocq_proof/Example.v) / [OCaml](examples/ocaml_example/Main.ml)) for more details.

## Layout of this repository

This repository is structured as follows:

```
.
├── mechanization
│   ├── spec
│   │   └── base
│   ├── props
│   ├── tactics
│   └── utils
├── engines
│   ├── common
│   ├── ocaml
│   └── js
├── examples
│   ├── browser_playground
│   ├── cmd_playground
│   ├── rocq_proof
│   └── ocaml_example
└── tests
    ├── tests
    ├── fuzzer
    └── test262
```

- **[Mechanization](#mechanization)**: Warblre proper, the mechanization in Rocq of the ECMAScript semantics of regexes.
- **[Engines](#engines)**: Extraction directives and extra code to allow a smooth usage of the extracted engine in different programming languages. Most of the code is in `common`; the other directories contain code specific to one particular language.
- **Examples**: Code snippets which show how to use the mechanization and extracted engines.
- **Tests:**
  - **Tests**: Unit tests for the OCaml engine.
  - **Fuzzer**: A differential fuzzer comparing the extracted JavaScript engine with the one from the host JavaScript environment.
  - **Test262**: A thin wrapper which allows to test the extracted JavaScript engine against [Test262](https://github.com/tc39/test262), the standard test suite for JavaScript engines; see the related [documentation](doc/Test262.md).

## Understanding Warblre

### Running examples

- `dune exec example` will run an example of matching a string with a regex ([source](examples/ocaml_example/Main.ml)).
- **[Requires JavaScript dependencies]**
    `dune exec fuzzer` will build and run the fuzzer to compare the extracted engine against Irregexp (Node.js's regex engine).
- `dune build examples/rocq_proof` will build everything so that you can step through [examples/rocq-proof/Example.v](examples/rocq_proof/Example.v).

### Mechanization

The [`mechanization`](./mechanization/) directory contains the Rocq code mechanizing the subset of the ECMAScript specification which describes regexes and their semantics.
It is based on the 14th edition from June 2023, available [here](https://262.ecma-international.org/14.0/).
Regexes are described in chapter [22.2](https://tc39.es/ecma262/2023/multipage/text-processing.html#sec-regexp-regular-expression-objects).

The way regexes work can be described using the following pipeline:

![The matching pipeline](etc/matching_pipeline/picture.svg)

A regex is first parsed;
it is then checked for *early errors*, and rejected if any are found;
it is then compiled into a *matcher*;
it is finally called with a concrete input string and start position, and yield a match if one is found.

The mechanization covers the last three phases; parsing is not included.

The mechanization depends on external types and parameters (for instance for unicode character manipulation functions).
This is encoded with a functor, whose parameter is described in `mechanization/spec/API.v`.

Files are organized as follows:
- **spec**: the mechanization in itself, translating the paper specification into Rocq.
- **props**: proofs about the specification. The main proofs are
    - *Compilation failure-free*: if a regex is early-errors-free, then its compilation into a matcher does not raise an error.
    - *Matching failure-free*: if a matcher is provided with valid inputs, then the matching process does not raise an error.
    - *Matching termination*: if a matcher is provided with valid inputs, then the matching process terminates.
    - *Strictly nullable optimisation*: Replacing the regex `r*` by the empty regex when `r` is a strictly nullable regex is a correct optimization.
- **tactics**: some general purpose tactics.
- **utils**: auxiliary definitions, such as extra operations and proofs on lists, the error monad, typeclasses, ...

### Executable regex engines

The [`engines`](./engines/) directory contains the code needed to turn the extracted code into two fully featured engines, one in OCaml and one in JavaScript.
For instance, this is where implementations for the abstract types and Unicode operations of the functor discussed above are provided.
Some of this code is common to the both engines, for instance a pretty-printer for regexes, and is stored in the `common` subdirectory.

The `ocaml` subdirectory contains code specific to the OCaml engine.
This includes functions to manipulate unicode characters, using the library `uucp`.

The `js` subdirectory contains code specific to the JavaScript engine.
This includes functions to manipulate unicode characters, some functions to work with [array exotic objects](https://262.ecma-international.org/14.0/#sec-array-exotic-objects) (see [`ArrayExotic.ml`](engines/js/ArrayExotic.ml)), and a parser for regexes, based on [regexpp](https://github.com/eslint-community/regexpp).

### More

The [`doc`](./doc/) directory contains some additional documentation documents.
- A list of differences between the mechanization and the specification: [`Differences.md`](doc/Differences.md);
- Discussions about some design choices: [`Implementation.md`](doc/Implementation.md);
- Documentation about testing the extracted engine against Test262: [`Test262.md`](doc/Test262.md);
- A list of differences between the [mechanization version](https://tc39.es/ecma262/2023/multipage/text-processing.html#sec-regexp-regular-expression-objects) of the specification (v14/2023), and the [following version](https://tc39.es/ecma262/2024/multipage/text-processing.html#sec-regexp-regular-expression-objects) (v15/2024): [`vFlag.md`](doc/vFlag.md).

## License

This codebase is licensed under the 3-Clause BSD License.
See [LICENSE](LICENSE) for details.

## Citing Warblre

Warblre was described in the following article:

> Noé De Santo, Aurèle Barrière, and Clément Pit-Claudel. 2024.
> A Coq Mechanization of JavaScript Regular Expression Semantics.
> Proc. ACM Program. Lang. 8, ICFP, Article 270 (August 2024), 29 pages.
> https://doi.org/10.1145/3674666

```bibtex
@article{10.1145/3674666,
    author = {De Santo, No\'{e} and Barri\`{e}re, Aur\`{e}le and Pit-Claudel, Cl\'{e}ment},
    title = {A Coq Mechanization of JavaScript Regular Expression Semantics},
    year = {2024},
    issue_date = {August 2024},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    volume = {8},
    number = {ICFP},
    url = {https://doi.org/10.1145/3674666},
    doi = {10.1145/3674666},
    journal = {Proc. ACM Program. Lang.},
    month = aug,
    articleno = {270},
    numpages = {29},
    keywords = {ECMAScript, Regex, Mechanization, Coq}
}
```
