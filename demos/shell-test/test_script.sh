#!/usr/bin/env bash

## IMPORTS
# shellcheck disable=SC1090
. "$(find "${PWD}" -name main.sh)"


function test_given_some_file_with_projetinho_word_when_call_fellas_function_then_should_to_return_a_message_from_toguro() {
    TEST_ID="test:fellas:test_given_some_file_with_projetinho_word_when_call_fellas_function_then_shold_return_a_message_from_toguro"

    TEMP_FILE=$(mktemp)
    echo "bora projetinho?" > "${TEMP_FILE}"

    EXPECTED="Bora fazer um projetinho fellas?"
    if [ "$(fellas "${TEMP_FILE}" | grep -c "${EXPECTED}")" -eq 1 ]; then
        echo "[PASS] - ${TEST_ID}"
    else
        echo "[FAIL] - ${FAIL}"
    fi

    rm -f "${TEMP_FILE}"
}

function test_given_some_file_without_projetinho_word_when_call_fellas_function_then_should_to_return_nothing() {
    TEST_ID="test:fellas:test_given_some_file_without_projetinho_word_when_call_fellas_function_then_shold_return_nothing"

    TEMP_FILE=$(mktemp)
    echo "bora projeto?" > "${TEMP_FILE}"

    EXPECTED="Bora fazer um projetinho fellas?"
    if [ "$(fellas "${TEMP_FILE}" | grep -c "${EXPECTED}")" -eq 0 ]; then
        echo "[PASS] - ${TEST_ID}"
    else
        echo "[FAIL] - ${TEST_ID}"
    fi

    rm -f "${TEMP_FILE}"
}