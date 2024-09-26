#!/usr/bin/env bash


## ---------- IMPORTS
. $(find "${PWD}" -type f -wholename "*/mig-automations/scripts/utils/utils.sh")



## ---------- VARIABLES
DEFAULT_LOG_LEVEL="DEBUG"
LOG_TO_FILE="/tmp/shellsuite.log"



## ---------- FUNCTIONS
function logger() {
    if [[ -z "${LOG_LEVEL}" ]]; then
        export LOG_LEVEL="${DEFAULT_LOG_LEVEL}"
    fi

    if [[ -z "${LOG_TO_FILE}" ]]; then
        export LOG_TO_FILE="true"
    fi

    if [[ "${LOG_TO_FILE}" == "true" ]]; then
        LOG_OUTPUT="${DEFAULT_LOG_OUTPUT}"
    elif [[ "${LOG_TO_FILE}" == "false" ]]; then
        LOG_OUTPUT="/dev/null"
    fi

    TIMESTAMP=$(date +'%Y/%m/%d %H:%M:%S')
    LEVEL=$1
    CLASS=$2
    MESSAGE=$3

    case "${LOG_LEVEL}" in
        "ERROR")
            echo -e "${TIMESTAMP} [${LEVEL}] [${CLASS}] - ${MESSAGE}" | grep -E "\[ERROR\]" | tee --output-error=warn -a "${LOG_OUTPUT}"
            ;;
        "WARN")
            echo -e "${TIMESTAMP} [${LEVEL}] [${CLASS}] - ${MESSAGE}" | grep -E "\[WARN\]" | tee --output-error=warn -a "${LOG_OUTPUT}"
            ;;
        "INFO")
            echo -e "${TIMESTAMP} [${LEVEL}] [${CLASS}] - ${MESSAGE}" | grep -E "\[INFO|WARN\]" | tee --output-error=warn -a "${LOG_OUTPUT}"
            ;;
        "DEBUG")
            echo -e "${TIMESTAMP} [${LEVEL}] [${CLASS}] - ${MESSAGE}" | tee --output-error=warn -a "${LOG_OUTPUT}"
            ;;
        *)
            echo -e "Invalid LOG_LEVEL: ${LOG_LEVEL}. Please choice one of these: ERROR, WARN, INFO, DEBUG"
            exit 1
        ;;
    esac
}

function get_os_info() {
    OS_NAME=$(grep "^ID=" /etc/os-release | cut -d "=" -f2)
    OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d "=" -f2 | tr -d '"')
    OS_FAMILY=$(grep "^ID_LIKE=" /etc/os-release | cut -d "=" -f2)
    echo "{\"name\": \"${OS_NAME}\", \"version\": \"${OS_VERSION}\", \"family\": \"${OS_FAMILY}\"}"
}

function install_pkg() {
    PKGS="$@"

    PKGS_TO_INSTALL=$(echo "${PKGS[@]}" | tr " " "\n" | wc -l)
    APPS_ALREADY_INSTALLED=$(echo "${PKGS[@]}" | tr ' ' '\n' | cut -d ':' -f2| xargs which | wc -l)
    if [[ "${PKGS_TO_INSTALL}" -ne "${APPS_ALREADY_INSTALLED}" ]]; then

        # Setup package manager
        if [[ $(uname) == "Linux" ]]; then
            which apt    &> /dev/null && PKGMAN="apt"
            which yum    &> /dev/null && PKGMAN="yum"
            which pacman &> /dev/null && PKGMAN="pacman"
        fi

        # Setup package manager install and update commands
        if [[ "${PKGMAN}" == "pacman" ]]; then
            PKGMAN_INSTALL_CMD="${PKGMAN} -S"
            PKGMAN_UPDATE_CMD="${PKGMAN} -Syu"
        else
            PKGMAN_INSTALL_CMD="${PKGMAN} install -y"
            PKGMAN_UPDATE_CMD="${PKGMAN} update"
        fi

        # Run package manager update
        which sudo && sudo ${PKGMAN} ${PKGMAN_UPDATE_CMD} || ${PKGMAN} ${PKGMAN_UPDATE_CMD}
        
        PKG_LIST=()
        for pkg in "${PKGS[@]}"; do
            pkg_name=$(echo "${pkg}" | cut -d: -f1)
            bin_name=$(echo "${pkg}" | cut -d: -f2)

            if ! which "${bin_name}" > /dev/null; then
                logger "DEBUG" "shellsuite:lib:install_pkg" "[MISSING] - ${bin_name}"
                PKG_LIST+=("${pkg_name}")
            else
                logger "DEBUG" "shellsuite:lib:install_pkg" "[PRESENT] - ${bin_name}"
            fi
        done

        if [ $(echo "${#PKG_LIST[@]}") -ge 1 ]; then
            which sudo && sudo ${PKGMAN} ${PKGMAN_INSTALL_CMD} "${PKG_LIST[@]}" || ${PKGMAN} ${PKGMAN_INSTALL_CMD} "${PKG_LIST[@]}"
        fi
    else
        logger "INFO" "shellsuite:lib:install_pkg" "All requirements are installed"
    fi
}

function check_error() {
    [[ "$#" -ne 1 ]] && logger "WARN" "shellsuite:lib:check_error" "Invalid args:\n\n$(echo '[missing-args] [required] [valid-values]\nexit-on-failure TRUE yes,no\nmessage FALSE error-message' | column -t)"
    [[ "$1" =~ yes|no ]] logger "WARN" "shellsuite:lib:check_error" "Invalid input for [exit-on-failure]. Valid values: true or false"

    EXIT_ON_FAILURE="$1"
    ERROR_MESSAGE="$2"

    [[ -z "${ERROR_MESSAGE}" ]] && [[ $? -ne 0 ]] && logger "ERROR" "shellsuite:lib:check_error[$0]" "${ERROR_MESSAGE}"
    [[ "${EXIT_ON_FAILURE}" == "true" ]] && exit 1
}

