#!/bin/bash

# MIT Licence | Łukasz Gajerski (https://github.com/Ukasz09)

HOME=$(eval echo "~${SUDO_USER}") # for proper work with sudo
EXTENSIONS_PATH=${HOME}"/code_lines_counter/extensions.txt"
IGNORE_PATH=${HOME}"/code_lines_counter/.gitignore"
EXTENSIONS_DELIMITER="|"
TOTAL_LINES_QTY=0

declare -A EXTENSIONS_DICT
declare -A RESULTS

# controller ------------------------------------------------------------------------- #
flag_processing(){
    OPTSPEC=":arhld-:"
    while getopts "$OPTSPEC" optchar; do
        case "${optchar}" in
            -)
                case "${OPTARG}" in
                    help)
                        show_help
                    ;;
                    dir)
                        local DIR_PATH="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        count_in_specific_dir "${DIR_PATH}"
                    ;;
                    add-lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        while $(is_param_for_flag ${!OPTIND}); do
                            EXT="${EXT} ${!OPTIND}"
                            OPTIND=$(( ++OPTIND ))
                        done
                        add_lang "${NAME}" "${EXT}"
                    ;;
                    remove-lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        while $(is_param_for_flag ${!OPTIND}); do
                            EXT="${EXT} ${!OPTIND}"
                            OPTIND=$(( ++OPTIND ))
                        done
                        remove_lang "${NAME}" "${EXT}"
                    ;;
                    list)
                        show_lang_list
                    ;;
                    show-ignored)
                        show_ignored
                    ;;
                    remove-ignored)
                        while $(is_param_for_flag ${!OPTIND}); do
                            ARGS="${ARGS} ${!OPTIND}"
                            OPTIND=$(( ++OPTIND ))
                        done
                        remove_ignored "${ARGS}"
                    ;;
                    add-ignored)
                        while $(is_param_for_flag ${!OPTIND}); do
                            ARGS="${ARGS} ${!OPTIND}"
                            OPTIND=$(( ++OPTIND ))
                        done
                        add_ignored "${ARGS}"
                    ;;
                    *)
                        check_flag_correctness
                    ;;
            esac;;
            h)
                show_help
            ;;
            d)
                local DIR_PATH="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                count_in_specific_dir "${DIR_PATH}"
            ;;
            a)
                local NAME="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                while $(is_param_for_flag ${!OPTIND}); do
                    EXT="${EXT} ${!OPTIND}"
                    OPTIND=$(( ++OPTIND ))
                done
                add_lang "${NAME}" "${EXT}"
            ;;
            r)
                local NAME="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                while $(is_param_for_flag ${!OPTIND}); do
                    EXT="${EXT} ${!OPTIND}"
                    OPTIND=$(( ++OPTIND ))
                done
                remove_lang "${NAME}" "${EXT}"
            ;;
            l)
                show_lang_list
            ;;
            *)
                check_flag_correctness
            ;;
        esac
    done
    
    # if no flag given
    if [ ${OPTIND} -eq 1 ]; then
        run_code_lines_report
    fi
}

is_param_for_flag(){
    PARAM=${1}
    if [[ ${PARAM} =~ ^-.* ]] || [ -z "${PARAM}" ]; then
        echo false
    fi
    echo true
}

show_lang_list(){
    divider="=========================================="
    divider=${divider}${divider}
    format=" | %-15s : %35s | \n"
    width=57
    
    echo
    printf " %${width}.${width}s \n" "${divider}"
    printf "   AVAILABLE LANGUAGES AND EXTENSIONS"
    printf "\n %${width}.${width}s \n" "${divider}"
    while read -r line; do
        local IFS=$'\n'
        local LANG=$(echo "$line" | cut -d "|" -f1)
        local EXT=$(echo "$line" | cut -d "|" -f 2-)
        printf "${format}" "${LANG}" "${EXT}"
    done < "${EXTENSIONS_PATH}" | sort
    printf " %${width}.${width}s" "${divider}"
    echo
    
}

show_help(){
    man code_lines_counter
}

show_ignored(){
    echo
    echo "==================================="
    echo " IGNORED EXTRA FILES / DIRECTORIES "
    echo "==================================="
    cat "${IGNORE_PATH}"
    echo "==================================="
    echo
}

add_lang(){
    read_available_extensions
    local NAME=${1}
    shift
    for EXTENSION in $@; do
        local IS_CORRECT=$(params_are_correct "${NAME}" "${EXTENSION}")
        if ${IS_CORRECT}; then
            # If exstension already exist
            local FOUND_LANG=$(get_lang_of_extension "${EXTENSION}")
            if [ -n "${FOUND_LANG}" ]; then
                echo "Not added. Extension: <${EXTENSION}> is already associated with: <${FOUND_LANG}>"
            else
                # If not found any available extensions for language
                if [ -z "${EXTENSIONS_DICT[${NAME}]}" ]; then
                    echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${EXTENSION}
                else
                    > "${EXTENSIONS_PATH}"
                    write_ext_with_ommiting_given_lang "${NAME}"
                    local NEW_EXT="${EXTENSIONS_DICT[$NAME]} ${EXTENSION}"
                    echo "${NAME}${EXTENSIONS_DELIMITER}${NEW_EXT}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${NEW_EXT}
                fi
                echo "Added: ${NAME} | ${EXTENSION}"
            fi
        else
            echo "Param cannot be empty !"
        fi
    done;
}

remove_lang(){
    read_available_extensions
    local NAME=${1}
    shift
    for EXTENSION in $@; do
        local IS_CORRECT=$(params_are_correct "${NAME}" "${EXTENSION}")
        if ${IS_CORRECT}; then
            local FOUND_LANG=$(get_lang_of_extension "${EXTENSION}")
            # If given language not exist
            if [ "${FOUND_LANG}" == "${NAME}" ]; then
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
                > "${EXTENSIONS_PATH}"
                write_ext_with_ommiting_given_lang "${NAME}"
                if [ -n "${EXTENSIONS_AFTER_REMOVE}" ]; then
                    echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSIONS_AFTER_REMOVE}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${EXTENSIONS_AFTER_REMOVE}
                fi
                echo "Correct removed: ${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}"
            else
                echo "Config file doesn't contain <${NAME}|${EXTENSION}> element !"
                if [ -n "${FOUND_LANG}" ]; then
                    echo "<${EXTENSION}> is associated with: <${FOUND_LANG}>"
                fi
            fi
        else
            echo "Param cannot be empty !"
        fi
    done
}

remove_ignored(){
    local arr=()
    while read -r line; do
        if [[ ! $@ =~ "${line}" ]]; then
            arr+=("${line}")
        else
            echo "Removed ignored: ${line}"
        fi
    done < "${IGNORE_PATH}"
    > "${IGNORE_PATH}"
    for i in "${arr[@]}"; do
        echo "${i}" >> "${IGNORE_PATH}"
    done
}

add_ignored(){
    for i in $@; do
        echo "${i}" >> "${IGNORE_PATH}"
        echo "Added ignored: ${i}"
    done
}

write_ext_with_ommiting_given_lang(){
    local GIVEN_LANG=${1}
    for key in "${!EXTENSIONS_DICT[@]}"; do
        if [ "${key}" != "${GIVEN_LANG}" ] ; then
            local VALUES=${EXTENSIONS_DICT[${key}]}
            echo "${key}${EXTENSIONS_DELIMITER}${VALUES}" >> "${EXTENSIONS_PATH}"
        fi
    done
}

params_are_correct(){
    local NAME="${1}"
    local EXTENSION="${2}"
    if [ -z "${NAME}" ] || [ -z "${EXTENSION}" ]; then
        echo false
    else
        echo true
    fi
}

get_lang_of_extension(){
    local SEARCHED="${1}"
    for key in "${!EXTENSIONS_DICT[@]}"; do
        for val in ${EXTENSIONS_DICT[${key}]}; do
            if [ "${val}" == "${SEARCHED}" ] ; then
                echo "${key}"
                return
            fi
        done
    done
    echo ""
}

check_flag_correctness(){
    if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
        "Unknown option -${OPTARG}" >&2
    fi
}

# logic ----------------------------------------------------------------------------- #
count_in_specific_dir(){
    cd "${1}" || exit 1
    run_code_lines_report
    cd - > /dev/null
}

read_available_extensions(){
    clear_extensions
    while read -r line; do
        local name=$(echo "$line" | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        local ext=$(echo "$line" | cut -d "|" -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        EXTENSIONS_DICT[$name]="$ext"
    done < "${EXTENSIONS_PATH}"
    sort -o "${EXTENSIONS_PATH}" "${EXTENSIONS_PATH}"
}

run_code_lines_report(){
    clear_results
    read_available_extensions
    jupyter_to_scripts
    calc_results
    calc_total_lines_qty
    print_results
    clear_jupyter_tmp_files
}

clear_results(){
    for key in "${!RESULTS[@]}"; do
        RESULTS[${key}]=""
    done
}

clear_extensions(){
    for key in "${!EXTENSIONS_DICT[@]}"; do
        unset RESULTS[${key}]
    done
}

# convert all jupter files to scripts
jupyter_to_scripts(){
    fdfind --ignore-file "${IGNORE_PATH}" -e "ipynb" -x jupyter nbconvert --to script --log-level=0 --output-dir=./code_counter_tmp/{//} {}
}

calc_results(){
    for key in "${!EXTENSIONS_DICT[@]}"; do
        qty=0
        for ext in ${EXTENSIONS_DICT[${key}]}; do
            lines_no=$(count_lines "${ext}")
            ((qty+=lines_no))
        done
        RESULTS[${key}]=${qty}
    done
}

count_lines(){
    fdfind --ignore-file "${IGNORE_PATH}" -e "${1}" -x wc -l | awk '{total += $1} END {print total}'
}

calc_total_lines_qty(){
    TOTAL_LINES_QTY=0
    for key in "${!RESULTS[@]}"; do
        TOTAL_LINES_QTY=$((TOTAL_LINES_QTY + RESULTS[${key}]))
    done
}

print_results(){
    divider="===================="
    divider=${divider}${divider}
    header="\n | %-13s | %10s | \n"
    format=" | %-13s : %10i | \n"
    width=30
    
    echo
    printf " %${width}.${width}s" "${divider}"
    printf "${header}" "LANGUAGE" "LINES_QTY"
    printf " %${width}.${width}s\n" "${divider}"
    for key in "${!RESULTS[@]}"; do
        if [ ! "${RESULTS[${key}]}" -eq "0" ]; then
            printf "${format}" ${key} ${RESULTS[${key}]}
        fi
    done | sort -r -t : -n -k 2
    printf " %${width}.${width}s\n" "${divider}"
    printf "${format}" "TOTAL" ${TOTAL_LINES_QTY}
    printf " %${width}.${width}s" "${divider}"
    echo
    echo
}

clear_jupyter_tmp_files(){
    if [ -d "./code_counter_tmp" ]; then rm -r ./code_counter_tmp; fi
}

# main ----------------------------------------------------------------------------- #
flag_processing $@