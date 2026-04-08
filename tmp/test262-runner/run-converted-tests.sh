#!/bin/bash
# Run regexp-modifiers tests from test262 PR #3960
# This script:
# 1. Converts regex literals to new RegExp() constructor calls
# 2. Runs the converted tests with warblre's test262 wrapper
#
# https://github.com/tc39/test262/pull/3960

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARBLRE_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONVERTER="${SCRIPT_DIR}/convert-regex-literals.py"

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
echo "RegExp Modifiers Test Runner (PR #3960)"
echo "=========================================="
echo ""
echo "WARBLRE_ROOT: ${WARBLRE_ROOT}"
echo "TEST262:      ${TEST262}"
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

# Converted tests directory
CONVERTED_DIR="${SCRIPT_DIR}/converted-tests"

# Source directory for regexp-modifiers tests
SOURCE_DIR="${TEST262}/test/built-ins/RegExp/regexp-modifiers"

if [ ! -d "${SOURCE_DIR}" ]; then
    echo "ERROR: regexp-modifiers tests not found in test262."
    echo "Please ensure your test262 clone includes PR #3960."
    exit 1
fi

echo "Step 1: Converting regex literals to new RegExp() calls..."
echo "Source:      ${SOURCE_DIR}"
echo "Converted:   ${CONVERTED_DIR}"
echo ""

# Clean up old converted tests
if [ -d "${CONVERTED_DIR}" ]; then
    rm -rf "${CONVERTED_DIR}"
fi

# Run the converter
python3 "${CONVERTER}" "${SOURCE_DIR}" "${CONVERTED_DIR}"

echo ""
echo "Step 2: Running converted tests with warblre..."
echo ""

# Build the list of test files
TEST_FILES=$(find "${CONVERTED_DIR}" -name "*.js" -type f)
TEST_COUNT=$(echo "${TEST_FILES}" | wc -l)

echo "Total tests to run: ${TEST_COUNT}"
echo "Timeout: ${TIMEOUT}ms"
echo "Threads: ${THREADS}"
echo "Output:  ${OUTPUT}"
echo ""

# Run the tests
# Note: We don't use set -e here because we want to see results even if some tests fail
set +e

# We need to copy converted files into the original test262 directory structure
# because test262-harness expects specific paths
echo "Copying converted files to test262 directory..."
cp -r "${CONVERTED_DIR}/"* "${TEST262}/test/built-ins/RegExp/regexp-modifiers/"

echo "Running test262-harness..."
cd "${TEST262}"
test262-harness \
    --timeout="${TIMEOUT}" \
    --threads="${THREADS}" \
    --host-type=node --host-path="${NODE}" \
    --host-args=--stack-size="${STACK_KB}" \
    --prelude="${PRELUDE}" \
    "${TEST262}/test/built-ins/RegExp/regexp-modifiers" > "${OUTPUT}" 2>&1 || true

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Tests complete!"
echo "=========================================="
echo "Output saved to: ${OUTPUT}"
echo ""

# Show summary
echo "Summary:"
echo "--------"
PASS=$(grep -c "^PASS" "${OUTPUT}" 2>/dev/null || echo "0")
FAIL=$(grep -c "^FAIL" "${OUTPUT}" 2>/dev/null || echo "0")

echo "PASS: ${PASS}"
echo "FAIL: ${FAIL}"
echo ""

if [ ${FAIL} -gt 0 ]; then
    echo "Failing tests:"
    grep "^FAIL" "${OUTPUT}" | head -20
    echo ""
fi

echo "Full results: ${OUTPUT}"
echo ""
echo "To run the OCaml tests (alternative):"
echo "  cd ${WARBLRE_ROOT}"
echo "  dune test tests/tests/RegExpModifiers.ml"

exit ${EXIT_CODE}
