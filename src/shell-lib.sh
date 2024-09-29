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

function check_args() {
  local arg_list=("$@")
  local invalid_args=()

  for arg_info in "${arg_list[@]}"; do
    local arg_name=$(echo "$arg_info" | cut -d':' -f1)
    local arg_type=$(echo "$arg_info" | cut -d':' -f2)
    local arg_required=$(echo "$arg_info" | cut -d':' -f3)
    local arg_valid_values=$(echo "$arg_info" | cut -d':' -f4)
    local arg_example=$(echo "$arg_info" | cut -d':' -f5)

    if [ "$arg_required" == "true" ] && [ -z "${!arg_name}" ]; then
      invalid_args+=("$arg_name           $arg_type      TRUE      $arg_valid_values        $arg_example")
    else
      case "$arg_type" in
        int)
          if ! [[ "${!arg_name}" =~ ^[0-9]+$ ]]; then
            invalid_args+=("$arg_name           $arg_type      $arg_required      $arg_valid_values        $arg_example")
          fi
          ;;
        str)
          if ! [[ "${!arg_name}" =~ ^[a-zA-Z0-9_/]+$ ]]; then
            invalid_args+=("$arg_name           $arg_type      $arg_required      $arg_valid_values        $arg_example")
          fi
          ;;
        *)
          log_error "Unsupported type: $arg_type"
          ;;
      esac
    fi
  done

  if [ ${#invalid_args[@]} -gt 0 ]; then
    log_error "Invalid arguments"

    echo -e "[missing-args] [type] [required] [valid-values] [examples]"
    for invalid_arg in "${invalid_args[@]}"; do
      echo "   $invalid_arg"
    done
    exit 1
  else
    echo "All arguments are valid."
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

function datetime_to_rfc2822() {
    input_datetime="$1"

    translate_month() {
        local month_pt="$1"
        case "$month_pt" in
            janeiro) echo "jan" ;;
            fevereiro) echo "feb" ;;
            março) echo "mar" ;;
            abril) echo "apr" ;;
            maio) echo "may" ;;
            junho) echo "jun" ;;
            julho) echo "jul" ;;
            agosto) echo "aug" ;;
            setembro) echo "sep" ;;
            outubro) echo "oct" ;;
            novembro) echo "nov" ;;
            dezembro) echo "dec" ;;
            *) echo "invalid" ;;
        esac
    }

    # 2024-09-29 21:56:10
    if [[ "$input_datetime" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
        formatted_datetime=$(date -d "$input_datetime" +"%a %d %b %Y %T %z")
    
    # 29 sep 2024 21:56:10
    elif [[ "$input_datetime" =~ ^[0-9]{2}\ [a-zA-Z]{3}\ [0-9]{4} ]]; then
        formatted_datetime=$(date -d "$input_datetime" +"%a %d %b %Y %T %z")
    
    # 29 de setembro de 2024 às 21:56:10
    elif [[ "$input_datetime" =~ ^[0-9]{2}\ de\ [a-zA-Z]+\ de\ [0-9]{4}\ às\ [0-9]{2}:[0-9]{2}:[0-9]{2} ]]; then
        month_pt=$(echo "$input_datetime" | sed -n 's/.*de \([a-zA-Z]\+\) de.*/\1/p')
        month_en=$(translate_month "$month_pt")
        
        if [[ "$month_en" == "invalid" ]]; then
            echo "Mês inválido fornecido: $month_pt"
            return 1
        fi

        normalized_datetime=$(echo "$input_datetime" | sed -e 's/ de / /g' -e 's/ às / /g' -e "s/$month_pt/$month_en/")
        formatted_datetime=$(date -d "$normalized_datetime" +"%a %d %b %Y %T %z")
    else
        echo "Date format not supported"
        return 1
    fi

    echo "$formatted_datetime"
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

function extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.rar)      unrar e "$1"   ;;
            *.tar.bz2)  tar -jxvf "$1" ;;
            *.tar.gz)   tar -zxvf "$1" ;;
            *.bz2)      bunzip2 "$1"   ;;
            *.gz)       gunzip "$1"    ;;
            *.tar)      tar -xvf "$1"  ;;
            *.tbz2)     tar -jxvf "$1" ;;
            *.tgz)      tar -zxvf "$1" ;;
            *.zip)      unzip "$1"     ;;
            *)          echo "'$1' cannot be extracted/mounted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file to extract"
    fi
}

function rotate() {
    [[ "$#" -ne 1 ]] && logger "WARN" "shellsuite:lib:rotate" "Invalid args:\n\n$(echo '[missing-args] [required] [valid-values]\nfilenames TRUE file.txt' | column -t)"
    for file in "$@"; do
        NOW=$(date +%Y%m%dT%H%M%S)
        cp "${file}" "${file}-${NOW}" && cp /dev/null "${file}"
    done
}

function check_connectivity() {
    [[ "$#" -ne 1 ]] && logger "WARN" "shellsuite:lib:check_connectivity" "Invalid args:\n\n$(echo '[missing-args] [required] [valid-values]\ntarget_ip TRUE 10.10.0.100\ntarget_port TRUE 8080' | column -t)"
    target_ip="$1"
    target_port="$2"
    time nc -zv "${target_ip}" "${target_port}"
}

function grow_and_resize_disk() {
    [[ "$#" -ne 1 ]] && logger "WARN" "shellsuite:lib:grow_and_resize_disk" "Invalid args:\n\n$(echo '[missing-args] [required] [valid-values]\ndevice TRUE /dev/sda\npartition TRUE 1' | column -t)"
    sudo growpart  ${device} ${partition}
    sudo resize2fs ${device}
}

function reset_commit_author() {
    LAST_COMMIT_AUTHOR=$(echo $(git log -1 --pretty=format:"%an"))
    CURRENT_USER=$(git config user.name)

    if [[ "${LAST_COMMIT_AUTHOR}" == ${CURRENT_USER} ]]; then
        logger "WARN" "reset_commit_author" "The last commit author and the current git user are the same. Switch to another user and try again."
        exit 0
    fi

    git commit --amend --reset-author --no-edit
}

function ssh_proxy() {
    PROXY_SERVER_IP="$1"
    PROXY_SERVER_USER="$2"
    PROXY_SERVER_SSHKEY_PATH="${3}"
    TARGET_INSTANCE_IP="$4"
    TARGET_INSTANCE_PORT="$5"
    
    ssh -L ${TARGET_INSTANCE_PORT}:${TARGET_INSTANCE_IP}:${TARGET_INSTANCE_PORT} -i ${PROXY_SERVER_SSHKEY_PATH} -N ${PROXY_SERVER_USER}@${PROXY_SERVER_IP}

    SSH_PORT_FORWARD_PID=$(pgrep -f 'ssh -L')
    logger "INFO" "ssh_proxy" "ssh-proxy running via PID: ${SSH_PORT_FORWARD_PID}"
}

function install_gcp_ops_agent() {
    curl -sS https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh | sudo bash -s -- --also-install
}

function get_k8s_resource_with_field() {
    resource_type="$1"
    field_pattern="$2"
    namespace="$3"
    kubectl get ${resource_type} -o jsonpath="{range .items[?(@"${field_pattern}")]}{.metadata.name}{\\"\n\\"}{end}" --namespace "${namespace}"
}

function get_k8s_resource_with_key_value_field() {
    resource_type="$1"
    pattern_key="$2"
    pattern_value="$3"
    namespace="$4"
    kubectl get ${resource_type} -o json -n ${namespace} | jq -r ".items[] | select(${pattern_key} == "${pattern_value}") | .metadata.name"
}

function past_commit() {
    INPUT_DATETIME="$1"
    COMMIT_MESSAGE="$2"

    COMMIT_DATE=$(datetime_to_rfc2822 "${INPUT_DATETIME}")
    GIT_COMMITTER_DATE="${COMMIT_DATE}" git commit -m "${COMMIT_MESSAGE}" --no-edit --date "${COMMIT_DATE}"
}
