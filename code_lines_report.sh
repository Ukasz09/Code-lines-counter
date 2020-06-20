#!/bin/bash
HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
EXTENSIONS_FILE_PATH=${HOME}"/code_lines_report/extensions.txt"

declare -A extensions
declare -A results

read_available_extensions(){
    while read line; do
        name=$(echo $line | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        ext=$(echo $line | cut -d "|" -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        extensions[$name]="$ext"
    done < ${EXTENSIONS_FILE_PATH}
}

##########

count_lines(){
    fdfind -e $1 -x wc -l | awk '{total += $1} END {print total}'
}

# convert all jupter files to scripts
jupyter_to_scripts(){
    fdfind -e "ipynb" -x jupyter nbconvert --to script --log-level=0
}

# because need more than one file extension
calc_cpp_results(){
    cpp_extensions=("cpp" "h" "c" "ino" "hpp" "cmake")
    cpp_qty=0
    for ext in ${!cpp_extensions[*]}
    do
        lines_no=$(count_lines ${cpp_extensions[$ext]})
        ((cpp_qty+=lines_no))
    done
    results["C/C++"]=${cpp_qty}
}

calc_results(){
    for key in ${!extensions[@]}; do
        qty=$(count_lines ${extensions[${key}]})
        if [ -z "${qty}" ]; then
            qty=0
        fi
        results[${key}]=${qty}
    done
}

print_results(){
    for key in ${!results[@]}; do
        echo ${key} ": " ${results[${key}]}
    done | sort -r -t : -n -k 2
}

read_available_extensions
# jupyter_to_scripts
# calc_results
# calc_cpp_results
# print_results
for key in ${!extensions[@]}; do
    echo ${key} ":" ${extensions[${key}]}
done

