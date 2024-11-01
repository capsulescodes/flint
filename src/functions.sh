function format_for_local
{
    local config="$1"

    local files="$2"

    local linters=$( echo "$( tr -d '\n' < "$config" )" | sed -n 's/.*"linters"[[:space:]]*:[[:space:]]*\(\[.*\]\).*/\1/p'| sed 's/^\[[[:space:]]*{/{/; s/}[[:space:]]*\]$/}/' | sed 's/},[[:space:]]*{/}{/g' | sed 's/}{/}\n{/g' )

    echo "$linters" | while IFS= read -r linter

    do
        if [[ -z "$linter" ]]

        then
            continue
        fi

        command=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"local"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        if [[ -z "$command" ]]

        then
            echo "\n\033[1;33mWarning : No local command associated with a linter. Skipping.\033[0m\n"

            continue
        fi

        extensions=$( echo "$linter" | sed -n 's/.*"extensions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d '" ' | tr ',' '|' )

        filtered=$( printf '%s\n' $files | grep -E "\.($extensions)$" )

        if [[ -n "$filtered" ]]

        then
            eval "$command" $filtered
        fi
    done
}



function format_for_remote
{
    local config="$1"

    local files="$2"

    local linters=$( echo "$( tr -d '\n' < "$config" )" | sed -n 's/.*"linters"[[:space:]]*:[[:space:]]*\(\[.*\]\).*/\1/p'| sed 's/^\[[[:space:]]*{/{/; s/}[[:space:]]*\]$/}/' | sed 's/},[[:space:]]*{/}{/g' | sed 's/}{/}\n{/g' )

    echo "$linters" | while IFS= read -r linter

    do
        if [[ -z "$linter" ]]

        then
            continue
        fi

        command=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"remote"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        if [[ -z "$command" ]]

        then
            echo "\n\033[1;33mWarning : No remote command associated with a linter. Skipping.\033[0m\n"

            continue
        fi

        extensions=$( echo "$linter" | sed -n 's/.*"extensions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d '" ' | tr ',' '|' )

        filtered=$( printf '%s\n' $files | grep -E "\.($extensions)$" )

        if [[ -n "$filtered" ]]

        then
            eval "$command" $filtered
        fi
    done
}
