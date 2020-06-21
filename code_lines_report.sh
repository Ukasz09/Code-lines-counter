#!/bin/bash
HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
EXTENSIONS_FILE_PATH=${HOME}"/code_lines_report/extensions.txt"

declare -A extensions
declare -A results

# controller ------------------------------------------------------------------------- #
flag_processing(){
    OPTSPEC=":arh-:"
    while getopts "$OPTSPEC" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    help)
                        showing_help
                        exit 0
                    ;;
                    add_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        adding_lang ${NAME} ${EXTENSION}
                        exit 0
                    ;;
                    remove_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        removing_lang ${NAME} ${EXTENSION}
                        exit 0
                    ;;
                    *)
                        if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
                            incorrect_flag_msg '--'${OPTARG}
                        fi
                        exit 1
                    ;;
            esac;;
            h)
                showing_help
                exit 0
            ;;
            a)
                local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                adding_lang ${NAME} ${EXTENSION}
                exit 0
            ;;
            r)
                local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                removing_lang ${NAME} ${EXTENSION}
                exit 0
            ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
                    incorrect_flag_msg '-'${OPTARG}
                fi
                exit 1
            ;;
        esac
    done
    
    # if no flag given
    if [ $OPTIND -eq 1 ]; then
        run_code_lines_report
    fi
}

showing_help(){
    echo "Here's showing help..." # TODO
}

adding_lang(){
    local NAME=${1}
    local EXTENSION=${2}
    check_lang_and_ext_correctness ${NAME} ${EXTENSION}
    echo "Here's processing of adding " ${NAME} ":" ${EXTENSION} # TODO
}

removing_lang(){
    local NAME=${1}
    local EXTENSION=${2}
    check_lang_and_ext_correctness ${NAME} ${EXTENSION}
    echo "Here's processing of removing " ${NAME} ":" ${EXTENSION} # TODO
}

check_lang_and_ext_correctness(){
    local NAME=${1}
    local EXTENSION=${2}
    if [ -z ${NAME} ]; then
        echo "Language name can't be empty !"
        exit 1
    fi
    if [ -z ${EXTENSION} ]; then
        echo "Extension name can't be empty !"
        exit 1
    fi
}

incorrect_flag_msg(){
    local FLAG=${1}
    echo "Unknown option ${FLAG}" >&2
}

# logic ----------------------------------------------------------------------------- #
read_available_extensions(){
    while read line; do
        name=$(echo $line | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        ext=$(echo $line | cut -d "|" -f2 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        extensions[$name]="$ext"
    done < ${EXTENSIONS_FILE_PATH}
}

run_code_lines_report(){
    echo "Running report" # TODO
}


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
flag_processing $@
# jupyter_to_scripts
# calc_results
# calc_cpp_results
# print_results
# for key in ${!extensions[@]}; do
# echo ${key} ":" ${extensions[${key}]}
# done

