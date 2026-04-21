# Agent: fix_test262_file

## Overview

The `fix_test262_file` agent generates complete, correct OCaml tests for a **single JavaScript test file** from the Test262 repository.

It reads the original JS test file, extracts all assertions, and generates the corresponding OCaml expect-tests following the project's conventions.

---

## Responsibilities

1. **Read the JS test file**
   - Parse the JavaScript test from the test262 repo
   - Extract all `assert()` calls and their metadata
   - Handle test262-specific patterns (test metadata, flags, etc.)

2. **Parse test assertions**
   - Extract regex patterns
   - Extract test inputs
   - Extract expected results (match/no-match)
   - Handle flags (i, m, s, u, v, etc.)

3. **Generate OCaml tests**
   - Create properly formatted `let%expect_test` blocks
   - Use correct Warblre notations (`BufferStart`, `BufferEnd`, etc.)
   - Generate appropriate `[%expect {| ... |}]` blocks
   - Follow the existing code style

4. **Update the OCaml file**
   - Insert the new tests in the correct section
   - Maintain proper file organization
   - Ensure the file compiles with `dune build`

5. **Validate**
   - Run `dune build` to ensure compilation
   - Fix any syntax errors

---

## Key Properties

- **Complete**: Generates ALL tests from the JS file, not just some
- **Accurate**: Matches the expected behavior from the JS test
- **Styled**: Follows the project's OCaml conventions
- **Validated**: Always ensures the code compiles

---

## Inputs

- js_test_file: Path to the JS test file in test262 repo (e.g., `test262/test/built-ins/RegExp/buffer-boundaries/syntax/u-mode.js`)
- ocaml_test_file: Path to the generated OCaml file (e.g., `tests/tests/Test262_BufferBoundaries.ml`)
- test262_repo_path: Path to test262 repo (e.g., `./test262`)
- branch: Branch name (e.g., `regexp-buffer-boundaries`)

---

## Outputs

- Structured report:
  - JS file processed
  - Number of assertions found
  - Number of tests generated
  - Build status
  - Any errors or warnings

---

## Constraints

- MUST read the ENTIRE JS file
- MUST generate tests for ALL assertions in the JS file
- MUST NOT skip any tests
- MUST ensure the generated code compiles
- MUST follow existing OCaml code style
- MUST use the convert script output format as reference

---

## Typical Use Cases

- Adding missing tests from a specific JS test file
- Regenerating tests for a file that was incompletely converted
- Updating tests when the JS source changes

---

## Summary

`fix_test262_file` ensures a single JS test file is completely and correctly converted to OCaml expect-tests.
