#!/usr/bin/env bash


function get_os() {
    grep "^ID=" /etc/os-release | cut -d "=" -f2
}



function install_pkg() {
    PKGS="$@"
    if [[ "$(echo "${PKGS[@]}" | tr " " "\n" | wc -l)" -ne "$(echo "${PKGS[@]}" | tr ' ' '\n' | cut -d ':' -f2| xargs which | wc -l)" ]]; then
        [[ -f /usr/bin/sudo ]] && sudo apt-get update || apt-get update
        
        PKG_LIST=()
        for pkg in "${PKGS[@]}"; do
            pkg_name=$(echo "${pkg}" | cut -d: -f1)
            bin_name=$(echo "${pkg}" | cut -d: -f2)

            if ! which "${bin_name}" > /dev/null; then
                logger "DEBUG" "setupProject" "[MISSING] - ${bin_name}"
                PKG_LIST+=("${pkg_name}")
            else
                logger "DEBUG" "setupProject" "[PRESENT] - ${bin_name}"
            fi
        done

        if [ $(echo "${#PKG_LIST[@]}") -ge 1 ]; then
            [[ -f /usr/bin/sudo ]] && sudo apt-get install -y "${PKG_LIST[@]}" || apt-get install -y "${PKG_LIST[@]}"
        fi
    else
        logger "INFO" "setupProject" "All requirements are installed"
    fi

}



function check_error() {
    [ $? -ne 0 ] && echo 1
}

