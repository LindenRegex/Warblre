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

# Resolve some basic paths
NODE=$(which node)
HARNESS=$(which test262-harness)
OUTPUT=test262.out.txt

# Stack size; the engine consumes a lot of stack space
STACK_kBytes=$((800*1024))

# Exclude experimental features
FEATURES_EXCL=--features-exclude="regexp-v-flag,regexp-duplicate-named-groups"

##################
# Category setup #
##################

# Test timeout
TIMEOUT_SEC=30
TIMEOUT_MIN=0
TIMEOUT_HRS=0
# Timeout must be in ms
TIMEOUT=$(( (($TIMEOUT_HRS*60 + $TIMEOUT_MIN)*60 + $TIMEOUT_SEC) * 1000 ))

# property-escapes tests are slow and for the most part not supported
TESTS=$(cd ${TEST262} && find test/built-ins/RegExp -name '*.js' \
       ! -regex '.*/property-escapes/.*')
echo Found "$(echo "${TESTS}" | wc -w)" tests before filtering.

# Number of tests run in parallel
THREADS_COUNT=4

##############
# Test setup #
##############

ulimit -s $STACK_kBytes
echo "Setting stack size limit to ${STACK_kBytes}KiB."
echo "Timeout is set to $TIMEOUT milliseconds (${TIMEOUT_HRS}h ${TIMEOUT_MIN}min ${TIMEOUT_SEC}sec)."
echo "Work output in ${OUTPUT}."
echo "${THREADS_COUNT} tests will run in parallel."

#################
# Run the tests #
#################

echo "Running test262..."
(cd ${TEST262} &&
    time "${HARNESS}" \
        --timeout="${TIMEOUT}" \
        --threads="${THREADS_COUNT}" \
        --host-type=node --host-path="${NODE}" \
        --host-args=--stack-size="${STACK_kBytes}" \
        --prelude="${WARBLRE}/_build/default/test262/warblre-node-redirect.js" \
        "${FEATURES_EXCL}" ${TESTS} > "${OUTPUT}")
echo "... done."
