function format_for_local
{
    local config="$( cat $1 )"

    local files="$2"

    if ! command -v jq &> /dev/null || [ "$( type -t jq )" != "file" ]

    then
        printf "\n\033[0;31mError: jq is not installed. Please install it to use this function.\033[0m\n"

        return 1
    fi

    for (( index=0; index < "$( echo "$config" | jq '.linters | length' )"; index++ ))

    do
        local command=$( echo "$config" | jq -r ".linters[$index].local // empty" )

        if [[ -z "$command" ]]

        then
            printf "\n\033[1;33mWarning : No local command associated to linter $d. Skipping.\033[0m\n" "$index"

            continue
        fi

        local extensions=$( echo "$config" | jq -r ".linters[$index].extensions | join(\"|\")" )

        local filtered=$( printf '%s\n' $files | grep -E "\.($extensions)$" )

        if [[ -n "$filtered" ]]

        then
            eval "$command" $filtered
        fi
    done
}


function format_for_remote
{
    local config="$( cat $1 )"

    local files="$2"

    if ! command -v jq &> /dev/null || [ "$( type -t jq )" != "file" ]

    then
        printf "\n\033[0;31mError: jq is not installed. Please install it to use this function.\033[0m\n"

        return 1
    fi

    for (( index=0; index < "$( echo "$config" | jq '.linters | length' )"; index++ ))

    do
        local command=$( echo "$config" | jq -r ".linters[$index].remote // empty" )

        if [[ -z "$command" ]]

        then
            printf "\n\033[1;33mWarning : No remote command associated to linter $d. Skipping.\033[0m\n" "$index"

            continue
        fi

        local extensions=$( echo "$config" | jq -r ".linters[$index].extensions | join(\"|\")" )

        local filtered=$( printf '%s\n' $files | grep -E "\.($extensions)$" )

        if [[ -n "$filtered" ]]

        then
            eval "$command" $filtered
        fi
    done
}
