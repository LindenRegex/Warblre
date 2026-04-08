#!/bin/bash
# Attempt to run regexp-modifiers tests from test262 PR #3960
# https://github.com/tc39/test262/pull/3960
#
# IMPORTANT LIMITATION:
# The RegExp Modifiers feature uses new syntax like (?i:), (?s:), (?m:) which is
# only supported in ES2025. Node.js/V8 cannot parse these regex literals, so
# the tests fail at the JavaScript parse stage - before warblre can intercept.
#
# This script will run but all tests will likely FAIL with SyntaxError because
# V8's parser doesn't recognize the (?s:) syntax.
#
# The only way to properly test this is to use the translated OCaml tests in:
#   tests/tests/RegExpModifiers.ml

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARBLRE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Check if TEST262 environment variable is set
if [ -z "${TEST262}" ]; then
    echo "ERROR: TEST262 environment variable is not set."
    echo "Please set it to the path of your test262 clone, e.g.:"
    echo "  export TEST262=/path/to/test262"
    exit 1
fi

# Check if test262-harness is installed
if ! command -v test262-harness &> /dev/null; then
    echo "ERROR: test262-harness is not installed."
    echo "Please install it with: npm install -g test262-harness"
    exit 1
fi

# Check if the test262 directory exists
if [ ! -d "${TEST262}" ]; then
    echo "ERROR: TEST262 directory does not exist: ${TEST262}"
    exit 1
fi

# Check if the warblre-node-redirect.js exists
PRELUDE="${WARBLRE_ROOT}/_build/default/tests/test262/warblre-node-redirect.js"
if [ ! -f "${PRELUDE}" ]; then
    echo "ERROR: warblre-node-redirect.js not found."
    echo "Please build it first with: dune build test262"
    exit 1
fi

echo "=========================================="
echo "Running RegExp Modifiers Tests (PR #3960)"
echo "=========================================="
echo ""
echo "WARBLRE_ROOT: ${WARBLRE_ROOT}"
echo "TEST262:      ${TEST262}"
echo "PRELUDE:      ${PRELUDE}"
echo ""
echo "=========================================="
echo "IMPORTANT LIMITATION"
echo "=========================================="
echo ""
echo "The RegExp Modifiers feature uses ES2025 syntax like (?i:), (?s:), (?m:)"
echo "which Node.js/V8 cannot parse. This causes SyntaxError BEFORE warblre"
echo "can intercept the regex operations."
echo ""
echo "Expected result: All tests will FAIL with SyntaxError"
echo ""
echo "To properly test this feature, use the OCaml tests:"
echo "  cd ${WARBLRE_ROOT}"
echo "  dune test tests/tests/RegExpModifiers.ml"
echo ""
echo "=========================================="
echo ""

# Test timeout (30 seconds)
TIMEOUT=30000

# Number of parallel threads
THREADS=4

# Path to node
NODE=$(which node)

# Stack size (800MB)
STACK_KB=$((800*1024))

# Output file
OUTPUT="${SCRIPT_DIR}/test262-regexp-modifiers.out.txt"

# Exact list of test files from PR #3960
declare -a TEST_FILES=(
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase.js"
    "test/built-ins/RegExp/regexp-modifiers/add-dotAll.js"
    "test/built-ins/RegExp/regexp-modifiers/add-multiline.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-dotAll.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-multiline.js"
    "test/built-ins/RegExp/regexp-modifiers/add-remove-modifiers.js"
    "test/built-ins/RegExp/regexp-modifiers/nested-add-remove-modifiers.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-add-ignoreCase-within-remove-ignoreCase.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-add-dotAll-within-remove-dotAll.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-add-multiline-within-remove-multiline.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-remove-ignoreCase-within-add-ignoreCase.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-remove-dotAll-within-add-dotAll.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-remove-multiline-within-add-multiline.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-backreferences.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-characterClasses.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-characterEscapes.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-lower-b.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-lower-p.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-lower-w.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-upper-b.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-upper-p.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-affects-slash-upper-w.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-does-not-affect-dotAll-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-does-not-affect-ignoreCase-property.js"
    "test/built-ins/RegExp/regexp-modifiers/add-ignoreCase-does-not-affect-multiline-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-backreferences.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-characterClasses.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-characterEscapes.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-lower-b.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-lower-p.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-lower-w.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-upper-b.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-upper-p.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-affects-slash-upper-w.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-does-not-affect-dotAll-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-does-not-affect-ignoreCase-property.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-ignoreCase-does-not-affect-multiline-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-dotAll-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/add-dotAll-does-not-affect-dotAll-property.js"
    "test/built-ins/RegExp/regexp-modifiers/add-dotAll-does-not-affect-ignoreCase-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-dotAll-does-not-affect-multiline-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-dotAll-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-dotAll-does-not-affect-dotAll-property.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-dotAll-does-not-affect-ignoreCase-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-dotAll-does-not-affect-multiline-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-multiline-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/add-multiline-does-not-affect-dotAll-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-multiline-does-not-affect-ignoreCase-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/add-multiline-does-not-affect-multiline-property.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-multiline-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-multiline-does-not-affect-dotAll-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-multiline-does-not-affect-ignoreCase-flag.js"
    "test/built-ins/RegExp/regexp-modifiers/remove-multiline-does-not-affect-multiline-property.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-dotAll-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-ignoreCase-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/nesting-multiline-does-not-affect-alternatives-outside.js"
    "test/built-ins/RegExp/regexp-modifiers/changing-dotAll-flag-does-not-affect-dotAll-modifier.js"
    "test/built-ins/RegExp/regexp-modifiers/changing-ignoreCase-flag-does-not-affect-ignoreCase-modifier.js"
    "test/built-ins/RegExp/regexp-modifiers/changing-multiline-flag-does-not-affect-multiline-modifier.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/add-modifiers-when-not-set-as-flags.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/remove-modifiers-when-not-set-as-flags.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/add-modifiers-when-set-as-flags.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/remove-modifiers-when-set-as-flags.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/add-and-remove-modifiers.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/add-and-remove-modifiers-can-have-empty-remove-modifiers.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/add-modifiers-when-nested.js"
    "test/built-ins/RegExp/regexp-modifiers/syntax/valid/remove-modifiers-when-nested.js"
)

echo "Total tests to run: ${#TEST_FILES[@]}"
echo ""

# Verify all test files exist
echo "Verifying test files exist..."
MISSING=0
for file in "${TEST_FILES[@]}"; do
    full_path="${TEST262}/${file}"
    if [ ! -f "${full_path}" ]; then
        echo "  MISSING: ${file}"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "ERROR: ${MISSING} test files are missing."
    echo "Please ensure your test262 clone has the regexp-modifiers tests (PR #3960)."
    exit 1
fi

echo "All ${#TEST_FILES[@]} test files found."
echo ""
read -p "Continue anyway? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi
set +e

# Build the list of full paths
TEST_PATHS=""
for file in "${TEST_FILES[@]}"; do
    TEST_PATHS="${TEST_PATHS} ${TEST262}/${file}"
done

echo "Running tests with test262-harness..."
echo "Timeout: ${TIMEOUT}ms"
echo "Threads: ${THREADS}"
echo "Output:  ${OUTPUT}"
echo ""

# Run the tests
cd "${TEST262}"
test262-harness \
    --timeout="${TIMEOUT}" \
    --threads="${THREADS}" \
    --host-type=node --host-path="${NODE}" \
    --host-args=--stack-size="${STACK_KB}" \
    --prelude="${PRELUDE}" \
    ${TEST_PATHS} > "${OUTPUT}" 2>&1

echo ""
echo "=========================================="
echo "Tests complete!"
echo "=========================================="
echo "Output saved to: ${OUTPUT}"
echo ""

# Show summary
echo "Summary (expecting all FAIL due to SyntaxError):"
grep -E "(PASS|FAIL)" "${OUTPUT}" | tail -30 || echo "(Check ${OUTPUT} for full results)"
echo ""
echo "To run working tests, use:"
echo "  cd ${WARBLRE_ROOT}"
echo "  dune test tests/tests/RegExpModifiers.ml"
