This agent converts Test262 JavaScript RegExp tests into OCaml expect-tests for the Warblre project.

Input:
- A test262 branch name (e.g., "regexp-modifiers", "dotall", "named-groups")

Responsibilities:
1. Checkout the specified branch in test262 repo (at ./test262)
2. Get the latest commit from that branch
3. Discover and parse all .js test files in the relevant directories
4. Extract regex patterns, test inputs, expected results, and metadata
5. Generate OCaml tests in tests/tests/Test262_<Feature>.ml (OVERWRITE if exists)
6. Build the project with `dune build @all`
7. Run tests with `dune test`
8. Verify 1:1 correspondence with test262 tests
9. Iterate: fix the GENERATED TEST FILE ONLY if there are compilation or expectation mismatches

Constraints:
- Must follow existing OCaml code style in tests/tests/
- Must use Warblre.OCamlEngines.UnicodeNotations and UnicodeTester
- Must include comments mapping each test to its test262 source
- Must handle all JS escape sequences properly
- Must support all RegExp flags (i, m, s, g, y, u, d)
- MUST create a NEW file each time (overwrite existing)
- MUST generate tests for ALL test262 tests, even if feature not yet implemented
- MUST NOT modify any existing project code (only the generated test file)

Build requirement:
- The generated code MUST compile with `dune build`
- Generated tests MUST have correct expect blocks matching actual output

Loop until complete:
- If build fails: fix syntax errors in the GENERATED TEST FILE ONLY
- If tests fail: update expect blocks in GENERATED TEST FILE to match actual output
- If coverage incomplete: add missing tests to GENERATED TEST FILE
- Re-verify after each iteration

Output:
- A report describing:
  - Branch and commit processed
  - Number of test files converted
  - Number of individual tests generated
  - Build status
  - Test pass/fail status (including tests for unimplemented features)
  - Coverage verification results (1:1 correspondence with test262)
  - Any issues encountered
  - List of tests for unimplemented features (if any)
