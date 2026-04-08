#!/usr/bin/env bash

set -e

#############
# Variables #
#############

# Check variables
if [ -z "${WARBLRE}" ]; then
    echo "WARBLRE is unset (or empty)."
    exit -1
fi
WARBLRE=$(realpath ${WARBLRE})

if [ -z "${TEST262}" ]; then
    echo "TEST262 is unset (or empty)."
    exit -1
fi
TEST262=$(realpath ${TEST262})

# Check for branch argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <branch-name>"
    echo "Example: $0 regexp-modifiers"
    echo ""
    echo "This will run ONLY the test files that were added/modified"
    echo "in the latest commit of the specified branch."
    exit 1
fi

BRANCH="$1"

cd ${TEST262}

# Check if branch exists
if ! git rev-parse --verify ${BRANCH} > /dev/null 2>&1; then
    echo "Error: Branch '${BRANCH}' does not exist."
    echo "Available branches:"
    git branch -a | head -20
    exit 1
fi

# Get current branch to restore later
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Switch to the target branch
echo "Switching to branch: ${BRANCH}"
git checkout ${BRANCH}

# Get the latest commit info
LATEST_COMMIT=$(git log -1 --oneline)
LATEST_COMMIT_HASH=$(git log -1 --format=%H)
echo "Latest commit on ${BRANCH}: ${LATEST_COMMIT}"

# Find test files in the latest commit
TEST_FILES=$(git diff-tree --no-commit-id --name-only -r ${LATEST_COMMIT_HASH} | grep '^test/built-ins/RegExp/.*\.js$' || true)

if [ -z "${TEST_FILES}" ]; then
    echo ""
    echo "No RegExp test files found in the latest commit."
    echo "Files in latest commit:"
    git diff-tree --no-commit-id --name-only -r ${LATEST_COMMIT_HASH}
    echo ""
    echo "Restoring original branch: ${CURRENT_BRANCH}"
    git checkout ${CURRENT_BRANCH}
    exit 1
fi

TEST_COUNT=$(echo "${TEST_FILES}" | wc -w)
echo ""
echo "Found ${TEST_COUNT} RegExp test file(s) in the latest commit:"
echo "${TEST_FILES}"
echo ""

# Resolve some basic paths
NODE=$(which node)
HARNESS=$(which test262-harness)
OUTPUT="${WARBLRE}/test262-latest-${BRANCH}.out.txt"

# Stack size; the engine consumes a lot of stack space
STACK_kBytes=$((800*1024))

# Test timeout
TIMEOUT_SEC=30
TIMEOUT_MIN=0
TIMEOUT_HRS=0
# Timeout must be in ms
TIMEOUT=$(( (($TIMEOUT_HRS*60 + $TIMEOUT_MIN)*60 + $TIMEOUT_SEC) * 1000 ))

# Number of tests run in parallel
THREADS_COUNT=4

##############
# Test setup #
##############

# Try to set stack size, but don't fail if it doesn't work (e.g., on macOS with limits)
ulimit -s $STACK_kBytes 2>/dev/null || echo "Warning: Could not set stack size to ${STACK_kBytes}KiB (current: $(ulimit -s)KiB)"
echo "Timeout is set to $TIMEOUT milliseconds (${TIMEOUT_HRS}h ${TIMEOUT_MIN}min ${TIMEOUT_SEC}sec)."
echo "Work output in ${OUTPUT}."
echo "${THREADS_COUNT} tests will run in parallel."
echo ""

#################
# Run the tests #
#################

echo "Running test262 on ${TEST_COUNT} test file(s) from the latest commit..."
time "${HARNESS}" \
    --timeout="${TIMEOUT}" \
    --threads="${THREADS_COUNT}" \
    --host-type=node --host-path="${NODE}" \
    --host-args=--stack-size="${STACK_kBytes}" \
    --prelude="${WARBLRE}/_build/default/tests/test262/warblre-node-redirect.js" \
    ${TEST_FILES} > "${OUTPUT}"

TEST_STATUS=$?

echo ""
echo "... done."
echo "Results written to: ${OUTPUT}"

# Show summary
echo ""
echo "Summary of results:"
grep -E "(PASS|FAIL)" "${OUTPUT}" | tail -20

# Restore original branch
echo ""
echo "Restoring original branch: ${CURRENT_BRANCH}"
git checkout ${CURRENT_BRANCH}

exit ${TEST_STATUS}
