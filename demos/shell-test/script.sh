#!/usr/bin/env bash


function fellas() {
    file=$1
    
    echo -e "\n-----"
    while IFS= read -r line || [ -n "${line}" ]; do 
        if echo "${line}" | grep -qi "projetinho"; then
            echo -e "> ${line}\nBora fazer um projetinho fellas?"
        fi
        sleep 0.5
    done < "${file}"
    echo -e "-----\n"
}
