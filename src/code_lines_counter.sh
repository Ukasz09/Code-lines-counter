#!/bin/bash

# MIT Licence | Łukasz Gajerski (https://github.com/Ukasz09)

HOME=$(eval echo "~${SUDO_USER}") # for proper work with sudo
EXTENSIONS_PATH="${HOME}/code_lines_counter/extensions.txt"
SINGLE_COMMENTS_PATH="${HOME}/code_lines_counter/single_comments.txt"
MULTIPLE_COMMENTS_PATH="${HOME}/code_lines_counter/multiple_comments.txt"
IGNORE_PATH=${HOME}"/code_lines_counter/.gitignore"
SED_PATH="${HOME}/code_lines_counter/multiple_comments.sed"
DELIMITER="|"
TOTAL_LINES_QTY=0
TOTAL_COMMENTS_QTY=0
EMPTY_LINE_SED='/^\s*$/d'
LEADING_SPACES_SEED='s/^[[:space:]]*//'
TRAILING_SPACES_SEED='s/[[:space:]]*$//'

declare -A EXTENSIONS_DICT
declare -A SINGLE_COMMENTS_DICT
declare -A MULTIPLE_COMMENTS_DICT
declare -A RESULTS
declare -A COMMENT_RESULTS

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
                    add-single-comment)
                        LANG="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        SIGN="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        add_single_comment "${LANG}" "${SIGN}"
                    ;;
                    remove-single-comment)
                        LANG="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        remove_single_comment "${LANG}"
                    ;;
                    add-multiple-comment)
                        LANG="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        START_SIGN="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        END_SIGN="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        add_multiple_comment ${LANG} ${START_SIGN} ${END_SIGN}
                    ;;
                    remove-multiple-comment)
                        LANG="${!OPTIND}"; OPTIND=$(( ++OPTIND ))
                        remove_multiple_comment ${LANG}
                    ;;
                    show-comments-list)
                        show_comments_list
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

show_comments_list(){
    divider="=========================================="
    divider=${divider}${divider}
    format=" | %-15s : %15s : %17s | \n"
    header="\n | %-15s | %15s | %17s | \n"
    width=57
    
    echo
    printf " %${width}.${width}s" "${divider}"
    printf " ${header}" "LANGUAGE" "SINGLE COMMENT" "MULTIPLE COMMENT"
    printf " %${width}.${width}s \n" "${divider}"
    read_single_comments
    read_multiple_comments
    for LANG in "${!SINGLE_COMMENTS_DICT[@]}"; do
        local IFS=$'\n'
        local SINGLE_COMMENT=${SINGLE_COMMENTS_DICT[${LANG}]}
        local MULTIPLE_COMMENT=${MULTIPLE_COMMENTS_DICT[${LANG}]}
        printf "${format}" "${LANG}" "${SINGLE_COMMENT}" "${MULTIPLE_COMMENT}"
    done
    for LANG in "${!MULTIPLE_COMMENTS_DICT[@]}"; do
        if [ -z ${SINGLE_COMMENTS_DICT[${LANG}]} ]; then
            local MULTIPLE_COMMENT=${MULTIPLE_COMMENTS_DICT[${LANG}]}
            printf "${format}" "${LANG}" " " "${MULTIPLE_COMMENT}"
        fi
    done
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
        local IS_NOT_EMPTY=$(params_not_empty "${NAME}" "${EXTENSION}")
        if ${IS_NOT_EMPTY}; then
            # If exstension already exist
            local FOUND_LANG=$(get_lang_of_extension "${EXTENSION}")
            if [ -n "${FOUND_LANG}" ]; then
                echo "Not added. Extension: <${EXTENSION}> is already associated with: <${FOUND_LANG}>"
            else
                # If not found any available extensions for language
                if [ -z "${EXTENSIONS_DICT[${NAME}]}" ]; then
                    echo "${NAME}${DELIMITER}${EXTENSION}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${EXTENSION}
                else
                    > "${EXTENSIONS_PATH}"
                    write_ext_with_ommiting_given_lang "${NAME}"
                    local NEW_EXT="${EXTENSIONS_DICT[$NAME]} ${EXTENSION}"
                    echo "${NAME}${DELIMITER}${NEW_EXT}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${NEW_EXT}
                fi
                echo "Added: ${NAME} | ${EXTENSION}"
            fi
        else
            echo "Param cannot be empty !"
        fi
    done;
}

add_single_comment(){
    read_single_comments
    local NAME=${1}
    local COMMENT=${2}
    local IS_NOT_EMPTY=$(params_not_empty "${NAME}" "${COMMENT}")
    if ${IS_NOT_EMPTY}; then
        # If language don't have associated single comment
        if [ -z "${SINGLE_COMMENTS_DICT[${NAME}]}" ]; then
            echo "${NAME}${DELIMITER}${COMMENT}" >> "${SINGLE_COMMENTS_PATH}"
            SINGLE_COMMENTS_DICT[${NAME}]=${COMMENT}
        else
            > "${SINGLE_COMMENTS_PATH}"
            write_single_comment_with_ommiting_given_lang "${NAME}"
            echo "${NAME}${DELIMITER}${COMMENT}" >> "${SINGLE_COMMENTS_PATH}"
            SINGLE_COMMENTS_DICT[${NAME}]=${COMMENT}
        fi
        echo "Added: ${NAME} | ${COMMENT}"
        
    else
        echo "Parameters cannot be empty !"
    fi
}

add_multiple_comment(){
    read_multiple_comments
    local NAME=${1}
    local START_COMMENT=${2}
    local END_COMMENT=${3}
    if [[ -n ${START_COMMENT} && -n ${END_COMMENT} && -n ${NAME} ]]; then
        # If language don't have associated multiple comment
        local COMMENT="${START_COMMENT} ${END_COMMENT}"
        if [ -z "${MULTIPLE_COMMENTS_DICT[${NAME}]}" ]; then
            echo "${NAME}${DELIMITER}${COMMENT}" >> "${MULTIPLE_COMMENTS_PATH}"
            MULTIPLE_COMMENTS_DICT[${NAME}]=${COMMENT}
        else
            > "${MULTIPLE_COMMENTS_PATH}"
            write_multiple_comment_with_ommiting_given_lang "${NAME}"
            echo "${NAME}${DELIMITER}${COMMENT}" >> "${MULTIPLE_COMMENTS_PATH}"
            MULTIPLE_COMMENTS_DICT[${NAME}]=${COMMENT}
        fi
        echo "Added: ${NAME} | ${COMMENT}"
        
    else
        echo "Parameters cannot be empty !"
    fi
}

read_single_comments(){
    clear_single_comments
    while read -r line; do
        local lang=$(echo "$line" | cut -d "|" -f1 | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        local comment=$(echo "$line" | cut -d "|" -f2 | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        SINGLE_COMMENTS_DICT[$lang]="$comment"
    done < "${SINGLE_COMMENTS_PATH}"
}

read_multiple_comments(){
    clear_multiple_comments
    while read -r line; do
        local lang=$(echo "$line" | cut -d "|" -f1 | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        local comment=$(echo "$line" | cut -d "|" -f2 | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        MULTIPLE_COMMENTS_DICT[${lang}]="${comment}"
    done < "${MULTIPLE_COMMENTS_PATH}"
}

remove_multiple_comment(){
    read_multiple_comments
    local NAME=${1}
    if [ -n "${NAME}" ]; then
        if [ -n "${MULTIPLE_COMMENTS_DICT[${NAME}]}" ]; then
            > "${MULTIPLE_COMMENTS_PATH}"
            write_multiple_comment_with_ommiting_given_lang "${NAME}"
            echo "Correct removed multiple (block) comment for language: ${NAME}"
        else
            echo "Config file doesn't contain single comments sign for language <${NAME}> !"
        fi
    else echo "Language name cannot be empty !"
    fi
}

remove_lang(){
    read_available_extensions
    local NAME=${1}
    shift
    for EXTENSION in $@; do
        local IS_NOT_EMPTY=$(params_not_empty "${NAME}" "${EXTENSION}")
        if ${IS_NOT_EMPTY}; then
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
                    echo "${NAME}${DELIMITER}${EXTENSIONS_AFTER_REMOVE}" >> "${EXTENSIONS_PATH}"
                    EXTENSIONS_DICT[${NAME}]=${EXTENSIONS_AFTER_REMOVE}
                fi
                echo "Correct removed: ${NAME}${DELIMITER}${EXTENSION}"
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

remove_single_comment(){
    read_single_comments
    local NAME=${1}
    if [ -n "${NAME}" ]; then
        if [ -n "${SINGLE_COMMENTS_DICT[${NAME}]}" ]; then
            > "${SINGLE_COMMENTS_PATH}"
            write_single_comment_with_ommiting_given_lang "${NAME}"
            echo "Correct removed single comment for language: ${NAME}"
        else
            echo "Config file doesn't contain single comments sign for language <${NAME}> !"
        fi
    else echo "Language name cannot be empty !"
    fi
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
            echo "${key}${DELIMITER}${VALUES}" >> "${EXTENSIONS_PATH}"
        fi
    done
}

write_single_comment_with_ommiting_given_lang(){
    local GIVEN_LANG=${1}
    for key in "${!SINGLE_COMMENTS_DICT[@]}"; do
        if [ "${key}" != "${GIVEN_LANG}" ] ; then
            local VALUE=${SINGLE_COMMENTS_DICT[${key}]}
            echo "${key}${DELIMITER}${VALUE}" >> "${SINGLE_COMMENTS_PATH}"
        fi
    done
}

write_multiple_comment_with_ommiting_given_lang(){
    local GIVEN_LANG=${1}
    for key in "${!MULTIPLE_COMMENTS_DICT[@]}"; do
        if [ "${key}" != "${GIVEN_LANG}" ] ; then
            local VALUE=${MULTIPLE_COMMENTS_DICT[${key}]}
            echo "${key}${DELIMITER}${VALUE}" >> "${MULTIPLE_COMMENTS_PATH}"
        fi
    done
}

params_not_empty(){
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
    local DIR_PATH="${1}"
    cd "${DIR_PATH}" || exit 1
    run_code_lines_report "${DIR_PATH}"
    cd - > /dev/null
}

read_available_extensions(){
    clear_extensions
    while read -r line; do
        local name=$(echo "$line" | cut -d "|" -f1 | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        local ext=$(echo "$line" | cut -d "|" -f 2- | sed -e "${LEADING_SPACES_SEED}" -e "${TRAILING_SPACES_SEED}")
        EXTENSIONS_DICT[$name]="$ext"
    done < "${EXTENSIONS_PATH}"
    sort -o "${EXTENSIONS_PATH}" "${EXTENSIONS_PATH}"
}

run_code_lines_report(){
    echo
    echo "Generating lines report. Please wait ..."
    echo
    clear_results
    read_available_extensions
    read_single_comments
    read_multiple_comments
    jupyter_to_scripts
    calc_results
    calc_total_lines_qty
    print_report_title "${1}"
    print_results
    clear_jupyter_tmp_files
}

print_report_title(){
    local TITLE="${1}"
    if [ -n ${TITLE} ]; then
        echo "RESULT FOR: ${TITLE}"
    fi
}

clear_results(){
    for key in "${!RESULTS[@]}"; do
        RESULTS[${key}]=""
        COMMENT_RESULTS[${key}]=""
    done
}

clear_extensions(){
    for key in "${!EXTENSIONS_DICT[@]}"; do
        unset RESULTS[${key}]
    done
}

clear_single_comments(){
    for key in "${!SINGLE_COMMENTS_DICT[@]}"; do
        unset SINGLE_COMMENTS_DICT[${key}]
    done
}

clear_multiple_comments(){
    for key in "${!MULTIPLE_COMMENTS_PATH[@]}"; do
        unset MULTIPLE_COMMENTS_DICT[${key}]
    done
}

# convert all jupter files to scripts
jupyter_to_scripts(){
    fdfind --ignore-file "${IGNORE_PATH}" -e "ipynb" -x jupyter nbconvert --to script --log-level=0 --output-dir=./code_counter_tmp/{//} {}
}

calc_results(){
    for key in "${!EXTENSIONS_DICT[@]}"; do
        code_qty=0
        comments_qty=0
        for ext in ${EXTENSIONS_DICT[${key}]}; do
            local LINES=$(count_lines "${key}" "${ext}")
            local CODE_LINES=$(echo "${LINES}" | cut -d "|" -f1)
            local COMMENTS_LINES=$(echo "${LINES}" | cut -d "|" -f2)
            ((code_qty+=CODE_LINES))
            ((comments_qty+=COMMENTS_LINES))
        done
        RESULTS[${key}]=${code_qty}
        COMMENT_RESULTS[${key}]=${comments_qty}
    done
}

count_lines(){
    local TOTAL_QTY=$(fdfind --ignore-file "${IGNORE_PATH}" -e "${2}" -x sed ${EMPTY_LINE_SED} | wc -l | awk '{total += $1} END {print total}')
    local LANG=${1}
    local BLOCK_COMMENT_START=$(echo "${MULTIPLE_COMMENTS_DICT[${LANG}]}" | cut -d ' ' -f1)
    local BLOCK_COMMENT_END=$(echo "${MULTIPLE_COMMENTS_DICT[${LANG}]}" | cut -d ' ' -f2)
    
    if [[ -n ${BLOCK_COMMENT_START} && -n ${BLOCK_COMMENT_END} ]]; then
        make_block_comments_sed ${BLOCK_COMMENT_START} ${BLOCK_COMMENT_END} ${SED_PATH}
    else
        > "${SED_PATH}"
        echo
    fi
    local MULTIPLE_COM_SED="${SED_PATH}"
    
    local ONE_LINER_COMMENT=${SINGLE_COMMENTS_DICT[${LANG}]}
    if [[ -n ${ONE_LINER_COMMENT} ]]; then
        local SINGLE_COM_SED="/^[[:blank:]]*${ONE_LINER_COMMENT}/d;s/${ONE_LINER_COMMENT}.*//"
    else
        local SINGLE_COM_SED=''
    fi
    
    local WITHOUT_COMMENTS_QTY=$(fdfind --ignore-file "${IGNORE_PATH}" -e "${2}" -x sed "${SINGLE_COM_SED}" | sed -f "${MULTIPLE_COM_SED}" | sed "${EMPTY_LINE_SED}" | wc -l | awk '{total += $1} END {print total}')
    
    local COMMENTS_QTY=$((TOTAL_QTY-WITHOUT_COMMENTS_QTY))
    echo "${WITHOUT_COMMENTS_QTY}|${COMMENTS_QTY}"
}

calc_total_lines_qty(){
    TOTAL_LINES_QTY=0
    TOTAL_COMMENTS_QTY=0
    for key in "${!RESULTS[@]}"; do
        TOTAL_LINES_QTY=$((TOTAL_LINES_QTY + RESULTS[${key}]))
        TOTAL_COMMENTS_QTY=$((TOTAL_COMMENTS_QTY + COMMENT_RESULTS[${key}]))
    done
}

print_results(){
    divider="======================================================================================================================"
    divider=${divider}${divider}
    header="\n | %-13s | %10s | %11s | %15s | \n"
    format=" | %-13s : %10i : %14s : %20s | \n"
    summary_format=" | %-13s : %10i : %14i | \n"
    width=70
    
    echo
    printf " %${width}.${width}s" "${divider}"
    printf "${header}" "LANGUAGE" "CODE LINES" "COMMENTS LINES" "LANGUAGES PERCENTAGE"
    printf " %${width}.${width}s\n" "${divider}"
    for key in "${!RESULTS[@]}"; do
        if [ ! "${RESULTS[${key}]}" -eq "0" ]; then
            local CODE_QTY=${RESULTS[${key}]}
            local PERCENT=$(calc_percentage "${CODE_QTY}" "${TOTAL_LINES_QTY}")
            local COMMENTS_QTY=${COMMENT_RESULTS[${key}]}
            printf "${format}" "${key}" "${CODE_QTY}" "${COMMENTS_QTY}" "${PERCENT} %"
        fi
    done | sort -r -t : -n -k 2
    printf " %${width}.${width}s\n" "${divider}"
    printf "${summary_format}" "TOTAL" ${TOTAL_LINES_QTY} ${TOTAL_COMMENTS_QTY}
    printf " %46.47s" "${divider}"
    echo
    echo
}

calc_percentage(){
    local ACTUAL=${1}
    local TOTAL=${2}
    local PERCENT=$(echo "${ACTUAL} / ${TOTAL} * 100" | bc -l | xargs printf "%.2f")
    echo "${PERCENT}"
}

clear_jupyter_tmp_files(){
    if [ -d "./code_counter_tmp" ]; then rm -r ./code_counter_tmp; fi
}
############3
make_block_comments_sed(){
    local START=${1}
    local END=${2}
    local SED_PATH=${3}
    echo "/$START/ !b" > ${SED_PATH}
    echo ":a" >> ${SED_PATH}
    echo "/$END/ !{" >> ${SED_PATH}
    echo "N" >> ${SED_PATH}
    echo "b a" >> ${SED_PATH}
    echo "}" >> ${SED_PATH}
    echo "s/$START.*$END//" >> ${SED_PATH}
}

# main ----------------------------------------------------------------------------- #
flag_processing $@