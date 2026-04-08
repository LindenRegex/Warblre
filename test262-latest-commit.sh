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
    exit 1
fi

BRANCH="$1"

cd ${TEST262}

# Check if branch exists
if ! git rev-parse --verify ${BRANCH} > /dev/null 2>&1; then
    echo "Error: Branch '${BRANCH}' does not exist."
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
    echo "No RegExp test files found in the latest commit."
    git checkout ${CURRENT_BRANCH}
    exit 1
fi

TEST_COUNT=$(echo "${TEST_FILES}" | wc -w)
echo "Found ${TEST_COUNT} test file(s)"

# Create temp directory and copy full test262 structure
TEMP_DIR=$(mktemp -d)
echo "Temp directory: ${TEMP_DIR}"

# Copy entire test262 to temp
echo "Copying test262 to temp directory..."
cp -r "${TEST262}"/* "${TEMP_DIR}/"

# Transform the test files in place
echo "Transforming test files..."
for file in ${TEST_FILES}; do
    if [ -f "${TEMP_DIR}/${file}" ]; then
        node "${WARBLRE}/transform-file.js" "${TEMP_DIR}/${file}" "${TEMP_DIR}/${file}"
    fi
done

# Setup paths
NODE=$(which node)
HARNESS=$(which test262-harness)
OUTPUT="${WARBLRE}/test262-latest-${BRANCH}.out.txt"

STACK_kBytes=$((800*1024))
TIMEOUT_SEC=30
TIMEOUT=$((30000))
THREADS_COUNT=4

echo "Running tests..."
cd "${TEMP_DIR}"

# Run tests using test262-harness on the transformed files
"${HARNESS}" \
    --timeout="${TIMEOUT}" \
    --threads="${THREADS_COUNT}" \
    --host-type=node --host-path="${NODE}" \
    --host-args=--stack-size="${STACK_kBytes}" \
    --prelude="${WARBLRE}/_build/default/tests/test262/warblre-node-redirect.js" \
    ${TEST_FILES} > "${OUTPUT}" 2>&1 || true

echo ""
echo "Results:"
grep -E "(PASS|FAIL|Ran|passed)" "${OUTPUT}" | tail -20

# Cleanup and restore
rm -rf "${TEMP_DIR}"
git checkout ${CURRENT_BRANCH}

echo "Done"
