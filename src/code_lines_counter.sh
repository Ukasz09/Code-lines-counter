#!/bin/bash

# Copyright Łukasz Gajerski (https://github.com/Ukasz09)
# MIT LICENCE

HOME=$(eval echo ~${SUDO_USER}) # for proper work with sudo
EXTENSIONS_FILE_PATH=${HOME}"/code_lines_counter/extensions.txt"
EXTRA_GITIGNORE=${HOME}"/code_lines_counter/.gitignore"
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
                        local DIR_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        count_in_specific_dir ${DIR_PATH}
                    ;;
                    add_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        EXT=""
                        until [[ ${!OPTIND} =~ ^-.* ]] || [ -z ${!OPTIND} ]; do
                            EXT="${EXT} ${!OPTIND}"
                            OPTIND=$(( $OPTIND + 1 ))
                        done
                        add_lang ${NAME} ${EXT}
                    ;;
                    remove_lang)
                        local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        EXT=""
                        until [[ ${!OPTIND} =~ ^-.* ]] || [ -z ${!OPTIND} ]; do
                            EXT="${EXT} ${!OPTIND}"
                            OPTIND=$(( $OPTIND + 1 ))
                        done
                        remove_lang ${NAME} ${EXT}
                    ;;
                    list)
                        show_lang_list
                    ;;
                    *)
                        if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
                            incorrect_flag_msg '--'${OPTARG}
                        fi
                        exit 1
                    ;;
            esac;;
            h)
                show_help
            ;;
            d)
                local DIR_PATH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                count_in_specific_dir ${DIR_PATH}
            ;;
            a)
                local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                EXT=""
                until [[ ${!OPTIND} =~ ^-.* ]] || [ -z ${!OPTIND} ]; do
                    EXT="${EXT} ${!OPTIND}"
                    OPTIND=$(( $OPTIND + 1 ))
                done
                add_lang ${NAME} ${EXT}
            ;;
            r)
                local NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                EXT=""
                until [[ ${!OPTIND} =~ ^-.* ]] || [ -z ${!OPTIND} ]; do
                    EXT="${EXT} ${!OPTIND}"
                    OPTIND=$(( $OPTIND + 1 ))
                done
                remove_lang ${NAME} ${EXT}
            ;;
            l)
                show_lang_list
            ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${OPTSPEC:0:1}" = ":" ]; then
                    incorrect_flag_msg '-'${OPTARG}
                fi
            ;;
        esac
    done
    
    # if no flag given
    if [ $OPTIND -eq 1 ]; then
        run_code_lines_report
    fi
}

show_lang_list(){
    echo
    echo "==================================="
    echo "AVAILABLE LANGUAGES AND EXTENSIONS:"
    echo "==================================="
    local IFS=$'\n'
    for i in $(cat ${EXTENSIONS_FILE_PATH} | sort); do
        local LANG=$(echo $i | cut -d "|" -f1)
        local EXT=$(echo $i | cut -d "|" -f 2-)
        printf "%-15s : %s\n" $LANG $EXT
    done
    echo
    
}

show_help(){
    man code_lines_counter
}

add_lang(){
    read_available_extensions
    local NAME=${1}
    shift
    for EXTENSION in $@; do
        local IS_CORRECT=$(params_are_correct ${NAME} ${EXTENSION})
        if ${IS_CORRECT}; then
            # If exstension already exist
            local FOUND_LANG=$(get_lang_of_extension ${EXTENSION})
            if [ ! -z "${FOUND_LANG}" ]; then
                echo "Not added. Extension: <${EXTENSION}> is already associated with: <${FOUND_LANG}>"
            else
                # If not found any available extensions for language
                if [ -z "${EXTENSIONS_DICT[${NAME}]}" ]; then
                    echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}" >> ${EXTENSIONS_FILE_PATH}
                    EXTENSIONS_DICT[${NAME}]=${EXTENSION}
                else
                    > ${EXTENSIONS_FILE_PATH}
                    write_ext_with_ommiting_given_lang ${NAME}
                    local NEW_EXT="${EXTENSIONS_DICT[$NAME]} ${EXTENSION}"
                    echo "${NAME}${EXTENSIONS_DELIMITER}${NEW_EXT}" >> ${EXTENSIONS_FILE_PATH}
                    EXTENSIONS_DICT[${NAME}]=${NEW_EXT}
                fi
                echo "Added: " ${NAME} "|" ${EXTENSION}
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
        local IS_CORRECT=$(params_are_correct ${NAME} ${EXTENSION})
        if ${IS_CORRECT}; then
            local FOUND_LANG=$(get_lang_of_extension ${EXTENSION})
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
                > ${EXTENSIONS_FILE_PATH}
                write_ext_with_ommiting_given_lang ${NAME}
                if [ ! -z "${EXTENSIONS_AFTER_REMOVE}" ]; then
                    echo "${NAME}${EXTENSIONS_DELIMITER}${EXTENSIONS_AFTER_REMOVE}" >> ${EXTENSIONS_FILE_PATH}
                    EXTENSIONS_DICT[${NAME}]=${EXTENSIONS_AFTER_REMOVE}
                fi
                echo "Correct removed: ${NAME}${EXTENSIONS_DELIMITER}${EXTENSION}"
            else
                echo "Config file doesn't contain <${NAME}|${EXTENSION}> element !"
                if [ ! -z "${FOUND_LANG}" ]; then
                    echo "<${EXTENSION}> is associated with: <${FOUND_LANG}>"
                fi
            fi
        else
            echo "Param cannot be empty !"
        fi
    done
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

params_are_correct(){
    local NAME=${1}
    local EXTENSION=${2}
    if [ -z ${NAME} ] || [ -z ${EXTENSION} ]; then
        echo false
    else
        echo true
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
count_in_specific_dir(){
    cd ${1} || exit 1
    run_code_lines_report
    cd - > /dev/null
}

read_available_extensions(){
    while read line; do
        local name=$(echo $line | cut -d "|" -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        local ext=$(echo $line | cut -d "|" -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        EXTENSIONS_DICT[$name]="$ext"
    done < ${EXTENSIONS_FILE_PATH}
    sort -o ${EXTENSIONS_FILE_PATH} ${EXTENSIONS_FILE_PATH}
}

run_code_lines_report(){
    read_available_extensions
    jupyter_to_scripts
    calc_results
    calc_total_lines_qty
    print_results
    clear_jupyter_tmp_files
}

# convert all jupter files to scripts
jupyter_to_scripts(){
    fdfind --ignore-file ${EXTRA_GITIGNORE} -e "ipynb" -x jupyter nbconvert --to script --log-level=0 --output-dir=./code_counter_tmp/{//} {}
}

calc_results(){
    for key in ${!EXTENSIONS_DICT[@]}; do
        qty=0
        for ext in ${EXTENSIONS_DICT[${key}]}; do
            lines_no=$(count_lines ${ext})
            ((qty+=lines_no))
        done
        if [ ! "${qty}" -eq "0" ]; then
            RESULTS[${key}]=${qty}
        fi
    done
}

count_lines(){
    fdfind --ignore-file ${EXTRA_GITIGNORE} -e ${1} -x wc -l | awk '{total += $1} END {print total}'
}

calc_total_lines_qty(){
    TOTAL_LINES_QTY=0
    for key in ${!RESULTS[@]}; do
        TOTAL_LINES_QTY=$((${TOTAL_LINES_QTY} + ${RESULTS[${key}]}))
    done
}

print_results(){
    divider="===================="
    divider=${divider}${divider}
    header="\n | %-10s | %10s | \n"
    format=" | %-10s : %10i | \n"
    width=27
    
    echo
    printf " %${width}.${width}s" "${divider}"
    printf "${header}" "LANGUAGE" "LINES_QTY"
    printf " %${width}.${width}s\n" "${divider}"
    for key in ${!RESULTS[@]}; do
        printf "${format}" ${key} ${RESULTS[${key}]}
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