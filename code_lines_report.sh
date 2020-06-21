#!/bin/bash
HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
EXTENSIONS_FILE_PATH=${HOME}"/code_lines_report/extensions.txt"
LANG_EXT_DELIMITER="|"

declare -A EXTENSIONS_DICT
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
    read_available_extensions
    local ACTUAL_LANG_NAME=$(extensions_dict_contains_val ${EXTENSION})
    if [ ! -z "${ACTUAL_LANG_NAME}" ]; then
        echo "This language extension already exist in config file !"
        exit 1
    fi
    
    if [ -z "${EXTENSIONS_DICT[${NAME}]}" ]; then
        echo "${NAME}${LANG_EXT_DELIMITER}${EXTENSION}" >> ${EXTENSIONS_FILE_PATH}
    else
        > ${EXTENSIONS_FILE_PATH}
        for key in ${!EXTENSIONS_DICT[@]}; do
            if [ "${key}" != "${NAME}" ] ; then
                values=${EXTENSIONS_DICT[${key}]}
                echo "${key}${LANG_EXT_DELIMITER}${values}" >> ${EXTENSIONS_FILE_PATH}
            else
                echo "${key}${LANG_EXT_DELIMITER}${EXTENSIONS_DICT[$NAME]} ${EXTENSION}" >> ${EXTENSIONS_FILE_PATH}
            fi
        done
    fi
    echo "Added: " ${NAME} "|" ${EXTENSION}
}

removing_lang(){
    local NAME=${1}
    local EXTENSION=${2}
    check_lang_and_ext_correctness ${NAME} ${EXTENSION}
    read_available_extensions
    local ACTUAL_LANG_NAME=$(extensions_dict_contains_val ${EXTENSION})
    if [ "${ACTUAL_LANG_NAME}" != "${NAME}" ]; then
        echo "Config file doesn't contain <${NAME}|${EXTENSION}> element !"
        exit 1
    fi
    
    val_after_remove=""
    for val in ${EXTENSIONS_DICT[${ACTUAL_LANG_NAME}]}; do
        if [ "${val}" != "${EXTENSION}" ] ; then
            val_after_remove="${val_after_remove} ${val}"
        fi
    done
    val_after_remove=$(echo ${val_after_remove} | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    > ${EXTENSIONS_FILE_PATH}
    for key in ${!EXTENSIONS_DICT[@]}; do
        if [ "${key}" != "${NAME}" ] ; then
            values=${EXTENSIONS_DICT[${key}]}
            echo "${key}${LANG_EXT_DELIMITER}${values}" >> ${EXTENSIONS_FILE_PATH}
        else
            if [ ! -z "${val_after_remove}" ]; then
                echo "${key}${LANG_EXT_DELIMITER}${val_after_remove}" >> ${EXTENSIONS_FILE_PATH}
            fi
        fi
    done
    echo "Correct removed: ${NAME}${LANG_EXT_DELIMITER}${EXTENSION}"
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

extensions_dict_contains_val(){
    local VALUE=${1}
    for key in ${!EXTENSIONS_DICT[@]}; do
        for val in ${EXTENSIONS_DICT[${key}]}; do
            if [ "${val}" == "${VALUE}" ] ; then
                echo ${key}
                return
            fi
        done
    done
    echo ""
}

incorrect_flag_msg(){
    local FLAG=${1}
    echo "Unknown option ${FLAG}" >&2
}

# logic ----------------------------------------------------------------------------- #
read_available_extensions(){
    while read line; do
        name=$(echo $line | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        ext=$(echo $line | cut -d "|" -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        EXTENSIONS_DICT[$name]="$ext"
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
    for key in ${!EXTENSIONS_DICT[@]}; do
        qty=$(count_lines ${EXTENSIONS_DICT[${key}]})
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

# read_available_extensions

flag_processing $@
# jupyter_to_scripts
# calc_results
# calc_cpp_results
# print_results
# for key in ${!EXTENSIONS_DICT[@]}; do
# echo ${key} ":" ${EXTENSIONS_DICT[${key}]}
# done