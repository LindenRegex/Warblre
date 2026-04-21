# Agent: fix_test262_batch

## Overview

The `fix_test262_batch` agent orchestrates the COMPLETE generation of Test262 tests by processing files **one at a time**.

It decomposes the problem of generating a complete Test262 test file into smaller subproblems (one per original JS test file) and delegates each to the `fix_test262_file` agent.

---

## Responsibilities

1. **Parse the OCaml test file**
   - Identify all test sections and their corresponding original JS source files
   - Extract which tests belong to which file

2. **Compare against the actual test262 source**
   - For each JS test file, determine:
     - Which tests are already converted
     - Which tests are missing
     - Which tests need correction

3. **Decompose into subproblems**
   - Create one task per JS test file that needs fixing
   - Pass the relevant context to `fix_test262_file`

4. **Process sequentially**
   - Call `fix_test262_file` for each JS test file
   - Wait for each result before proceeding to the next
   - Aggregate results

---

## Key Properties

- **Incremental**: Processes one file at a time
- **Deterministic**: Same input → same output
- **Resumable**: Can continue from where it left off
- **Composable**: Works with `fix_test262_file` agent

---

## Inputs

- Path to the generated OCaml test file (e.g., `tests/tests/Test262_BufferBoundaries.ml`)
- Path to the test262 repo (e.g., `./test262`)
- Branch name in test262 repo (e.g., `regexp-buffer-boundaries`)

---

## Outputs

- Summary report:
  - Total JS source files found
  - Files processed
  - Tests added/fixed per file
  - Any errors encountered

---

## Constraints

- MUST process files sequentially (not in parallel)
- MUST wait for each `fix_test262_file` result before continuing
- MUST NOT skip files
- MUST provide complete context to `fix_test262_file`

---

## Typical Use Cases

- Fixing incomplete Test262 test conversions
- Adding missing tests from new test262 commits
- Updating tests when test262 source changes

---

## Summary

`fix_test262_batch` ensures thorough, file-by-file fixing of Test262 test conversions by delegating to specialized per-file agents.
