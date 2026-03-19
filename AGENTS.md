# AGENTS.md: Guidelines for AI Agents Working on Warblre

Warblre is a Rocq (formerly Coq) mechanization of ECMAScript regexes with extraction to OCaml and JavaScript.

## Build Commands

```bash
# Full build
opam exec -- dune build @all

# Build specific package
opam exec -- dune build -p warblre
opam exec -- dune build -p warblre-engines

# Clean build
opam exec -- dune clean && opam exec -- dune build @all

# Rocq documentation
opam exec -- dune build @doc
```

## Test Commands

```bash
# Run all tests
opam exec -- dune test --force --display=verbose

# Run specific test file (inline tests with ppx_expect)
opam exec -- dune test tests/tests/Tests.ml

# Verify compiled Rocq libraries
ALL_VOS=$(find _build/default/mechanization/ -name '*.vo')
opam exec -- rocqchk -silent --output-context -Q _build/default/mechanization Warblre $ALL_VOS

# Run specification conformance checker
cd specification_check && python3 main.py

# Run fuzzer (requires Node.js)
opam exec -- dune exec fuzzer
```

## Code Style Guidelines

### Rocq/Gallina
- **Imports**: Use `From Warblre Require Import ...` for local modules, `From Stdlib Require Import ...` for standard library
- **Naming**: 
  - Theorems/lemmas: descriptive lowercase with underscores (e.g., `match_terminates`)
  - Types: PascalCase (e.g., `RegExpRecord`, `MatchState`)
  - Modules: PascalCase
- **Definitions**: Document specification correspondence in comments (e.g., "[CompileSubPattern]")
- **Tactics**: Use custom tactics from `tactics/` directory; keep proof scripts maintainable

### OCaml
- **Imports**: Standard OCaml module system; use fully qualified names when ambiguous
- **Naming**: 
  - Modules: PascalCase
  - Functions/values: snake_case
  - Types: lowercase for type variables, PascalCase for concrete types
- **Formatting**: No explicit formatter configured; follow existing code style
- **Comments**: Document extracted code origins; link to specification sections

### JavaScript/ML (Melange)
- Located in `engines/js/`
- Follow OCaml conventions; extracted code uses `Js.*` bindings

### General
- Use `let*` for monadic binds in OCaml
- Prefer pattern matching over if-then-else
- Handle all cases in pattern matching (use wildcard `_` explicitly if needed)

## Project Structure

```
mechanization/     # Rocq mechanization (core)
  spec/           # ECMAScript specification translation
  props/          # Proofs (termination, safety, etc.)
  tactics/        # Custom tactics
  utils/          # Utilities (lists, monads, etc.)
engines/          # Extracted code
  common/         # Shared OCaml code
  ocaml/          # OCaml-specific implementations
  js/             # JavaScript/Melange implementations
tests/            # Test suites
examples/         # Usage examples
```

## Dependencies

- Rocq: 9.0.0 or 9.1.0
- OCaml: 4.14.2
- Key libraries: zarith, uucp, integers, melange, ppx_expect

## Error Handling

- Rocq: Use `Result` type from `utils/Result.v`
- OCaml: Use `result` type or exceptions for fatal errors; follow extraction patterns

## Verification Checklist

Before committing:
1. `dune build @all` succeeds (without any extra parameters)
2. `dune test` passes
3. `rocqchk` validates compiled libraries
4. Code follows repository naming conventions
5. Comments reference ECMAScript spec sections when applicable
