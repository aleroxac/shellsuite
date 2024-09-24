#!/usr/bin/env bash


function skip() {
  SKIP_PATTERN='#shelltest:skip\nfunction test_.*'
  TEST_FILES_GLOB="$(find "${PWD}" -name "test_*.sh")"
  functions_to_skip=$(grep -zoPh "${SKIP_PATTERN}" "${TEST_FILES_GLOB}" | grep -zoP "test_.*" | sed -E "s|(test_.*).*\(\).*|\1|g")
  
  for function in ${functions_to_skip[@]}; do
    sed -E "s|^(${function})|#\1|g" > "${TEST_FILES_GLOB}"
    echo "[SKIP] - ${function}"
  done
}

test_files=$(find "${PWD}" -name "test_*.sh" -not -name "shelltest.sh")
# shellcheck disable=SC1090
. "${test_files}"

skips=$(grep -zoPh '#shelltest:skip\nfunction test_.*' "${test_files}" | grep -zoP "test_.*" | sed -E "s|(test_.*).*\(\).*|\1|g" | xargs)
[ -z "${skips}" ] && skips=no_skips

tests=$(grep -E "^function test_*" "${test_files}" | sed -E "s/function (test_.*)\(\).*/\1/g" | grep -vE "${skips}")
RUNNED=$(echo "${tests}" | wc -l)
SKIPPED=$(echo "${skips}" | wc -l)
FAILED=0
PASSED=0

START_TIME=$(date +%s)
for test in ${tests[@]}; do
  if ${test} | grep PASS; then
    PASSED=$((PASSED+1))
  elif ${test} | grep FAIL; then
    FAILED=$((FAILED+1))
  fi
done
FINISH_TIME=$(date +%s)



DURATION_TIME=$(date -d @$((FINISH_TIME - START_TIME)) +%M:%S.%s)
STARTED_AT=$(date -d @${START_TIME} +'%Y-%m-%dT%H:%M:%S.%s')
FINISHED_AT=$(date -d @${START_TIME} +'%Y-%m-%dT%H:%M:%S.%s')

HEADER="\nRUNNED\tSKIPPED\tFAILED\tPASSED\tDURATION_TIME\tSTART_TIME\tFINISH_TIME"
DATA="${RUNNED}\t${SKIPPED}\t${FAILED}\t${PASSED}\t${DURATION_TIME}\t${STARTED_AT}\t${FINISHED_AT}"
echo -e "${HEADER}\n${DATA}" | column -Lt
