#!/bin/bash
HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
EXTENSIONS_FILE_PATH=${HOME}"/code_lines_report/extensions.txt"
EXTENSIONS_DELIMITER="|"

declare -A EXTENSIONS_DICT
declare -A RESULTS

# controller ------------------------------------------------------------------------- #
flag_processing(){
    OPTSPEC=":arh-:"
    while getopts "$OPTSPEC" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    help)
                        show_help
                        exit 0
                    ;;
                    add_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        add_lang ${NAME} ${EXTENSION}
                        exit 0
                    ;;
                    remove_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        remove_lang ${NAME} ${EXTENSION}
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
                add_lang ${NAME} ${EXTENSION}
                exit 0
            ;;
            r)
                local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                local EXTENSION="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                remove_lang ${NAME} ${EXTENSION}
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

show_help(){
    echo "Here's showing help..." # TODO
}

add_lang(){
    local NAME=${1}
    local EXTENSION=${2}
    check_correctness ${NAME} ${EXTENSION}
    read_available_extensions
    
    # If exstension already exist
    local FOUND_LANG=$(get_lang_of_extension ${EXTENSION})
    if [ ! -z "${FOUND_LANG}" ]; then
        echo "This language extension already exist in config file !"
        exit 1
    fi
    
    # If not found any available extensions for language
    if [ -z "${EXTENSIONS_DICT[${NAME}]}" ]; then
        echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}" >> ${EXTENSIONS_FILE_PATH}
    else
        > ${EXTENSIONS_FILE_PATH}
        write_ext_with_ommiting_given_lang ${NAME}
        echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSIONS_DICT[$NAME]} ${EXTENSION}" >> ${EXTENSIONS_FILE_PATH}
    fi
    echo "Added: " ${NAME} "|" ${EXTENSION}
}

remove_lang(){
    local NAME=${1}
    local EXTENSION=${2}
    check_correctness ${NAME} ${EXTENSION}
    read_available_extensions
    local FOUND_LANG=$(get_lang_of_extension ${EXTENSION})
    
    # If given language not exist
    if [ "${FOUND_LANG}" != "${NAME}" ]; then
        echo "Config file doesn't contain <${NAME}|${EXTENSION}> element !"
        if [ ! -z "${FOUND_LANG}" ]; then
            echo "<${EXTENSION}> is associated with: <${FOUND_LANG}>"
        fi
        exit 1
    fi
    
    # Removing extension
    EXTENSIONS_AFTER_REMOVE=""
    for val in ${EXTENSIONS_DICT[${FOUND_LANG}]}; do
        if [ "${val}" != "${EXTENSION}" ] ; then
            if [ -z "${EXTENSIONS_AFTER_REMOVE}" ]; then
                EXTENSIONS_AFTER_REMOVE="${val}"
            else
                EXTENSIONS_AFTER_REMOVE="${EXTENSIONS_AFTER_REMOVE} ${val}"
            fi
        fi
    done
    
    > ${EXTENSIONS_FILE_PATH}
    write_ext_with_ommiting_given_lang ${NAME}
    if [ ! -z "${EXTENSIONS_AFTER_REMOVE}" ]; then
        echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSIONS_AFTER_REMOVE}" >> ${EXTENSIONS_FILE_PATH}
    fi
    echo "Correct removed: ${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}"
}

write_ext_with_ommiting_given_lang(){
    local GIVEN_LANG=${1}
    for key in ${!EXTENSIONS_DICT[@]}; do
        if [ "${key}" != "${GIVEN_LANG}" ] ; then
            local VALUES=${EXTENSIONS_DICT[${key}]}
            echo "${key}${EXTENSIONS_DELIMITER}${VALUES}" >> ${EXTENSIONS_FILE_PATH}
        fi
    done
}

check_correctness(){
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

get_lang_of_extension(){
    local SEARCHED=${1}
    for key in ${!EXTENSIONS_DICT[@]}; do
        for val in ${EXTENSIONS_DICT[${key}]}; do
            if [ "${val}" == "${SEARCHED}" ] ; then
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
        local name=$(echo $line | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        local ext=$(echo $line | cut -d "|" -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
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
    RESULTS["C/C++"]=${cpp_qty}
}

calc_results(){
    for key in ${!EXTENSIONS_DICT[@]}; do
        qty=$(count_lines ${EXTENSIONS_DICT[${key}]})
        if [ -z "${qty}" ]; then
            qty=0
        fi
        RESULTS[${key}]=${qty}
    done
}

print_results(){
    for key in ${!RESULTS[@]}; do
        echo ${key} ": " ${RESULTS[${key}]}
    done | sort -r -t : -n -k 2
}

flag_processing $@
# jupyter_to_scripts
# calc_results
# calc_cpp_results
# print_results
# for key in ${!EXTENSIONS_DICT[@]}; do
# echo ${key} ":" ${EXTENSIONS_DICT[${key}]}
# done