function eval_for_command
{
    local name=$1

    local config=$2

    local files=$3

    local linters=$( echo "$( tr -d '\n' < $config )" | sed -n 's/.*"linters"[[:space:]]*:[[:space:]]*\(\[.*\]\).*/\1/p'| sed 's/^\[[[:space:]]*{/{/; s/}[[:space:]]*\]$/}/' | sed 's/},[[:space:]]*{/}{/g' | sed 's/}{/}\n{/g' )

    while IFS= read -r linter

    do
        if [[ -z "$linter" ]]

        then
            continue
        fi

        local binary=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"binary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        local command=$( echo "$linter" | tr -d '\n\r' | sed -n "s/.*\"$name\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" )

        if [[ -z "$binary" ]] || [[ -z "$command" ]]

        then
            printf "\033[1;33mWarning : No binary or '$name' command associated with a linter. Skipping.\033[0m\n"

            continue
        fi

        local extensions=$( echo "$linter" | sed -n 's/.*"extensions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d '" ' | tr ',' '|' )

        local filtered=$( [[ -n "$files" ]] && printf '%s\n' $files | grep -E "\.($extensions)$" | tr '\n' ' ' || echo "." )

        if [[ -n "$filtered" ]]

        then
            if [[ -x "$binary" ]]

            then
                eval $binary $command "$filtered"
            else
                printf "\033[1;33mWarning : Binary '$binary' not found. Install it and run 'flint run'. Skipping.\033[0m\n"
            fi
        fi
    done <<< "$linters"
}
