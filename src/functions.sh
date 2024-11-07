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

        binary=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"binary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        command=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"local"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        if [[ -z "$binary" ]] || [[ -z "$command" ]]

        then
            echo "\n\033[1;33mWarning : No binary or local command associated with a linter. Skipping.\033[0m\n"

            continue
        fi

        extensions=$( echo "$linter" | sed -n 's/.*"extensions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d '" ' | tr ',' '|' )

        filtered=$( [[ -n "$files" ]] && printf '%s\n' $files | grep -E "\.($extensions)$" | tr '\n' ' ' || echo "." )

        if [[ -n "$filtered" ]]

        then
            if [[ -x "$binary" ]]

            then
                eval "$binary" "$command" "$filtered"
            else
                echo "\n\033[1;33mWarning : Binary \""$binary"\" not found. Install it and run 'flint run'. Skipping.\033[0m\n"
            fi
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

        binary=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"binary"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        command=$( echo "$linter" | tr -d '\n\r' | sed -n 's/.*"remote"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' )

        if [[ -z "$binary" ]] || [[ -z "$command" ]]

        then
            echo "\n\033[1;33mWarning : No binary or remote command associated with a linter. Skipping.\033[0m\n"

            continue
        fi

        extensions=$( echo "$linter" | sed -n 's/.*"extensions"[[:space:]]*:[[:space:]]*\[\([^]]*\)\].*/\1/p' | tr -d '" ' | tr ',' '|' )

        filtered=$( [[ -n "$files" ]] && printf '%s\n' $files | grep -E "\.($extensions)$" | tr '\n' ' ' || echo "." )

        if [[ -n "$filtered" ]]

        then
            if [[ -x "$binary" ]]

            then
                eval "$binary" "$command" "$filtered"
            else
                echo "\n\033[1;33mWarning : Binary \""$binary"\" not found. Install it and run 'flint run'. Skipping.\033[0m\n"
            fi
        fi
    done
}
