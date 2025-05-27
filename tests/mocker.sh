function mock
{
    LOCAL=$1
    REMOTE=$2

    mkdir "$LOCAL/.git"

    mkdir "$LOCAL/.git/modified"
    mkdir "$LOCAL/.git/staged"
    mkdir "$LOCAL/.git/committed"
    mkdir "$LOCAL/.git/patched"

    touch "$LOCAL/.git/commits"
    touch "$LOCAL/.git/commands"


    function flint
    {
        source "$LOCAL/.core/bin/flint" "$@"
    }

    function wrap
    {
        if [[ -f "$LOCAL/.flint/git.sh" ]]; then source "$LOCAL/.flint/git.sh" "$@"; else git "$@"; fi
    }

    function eval_for_command
    {
        local files=()

        for file in $( [[ -z "${@:3}" ]] && ls -1 "$LOCAL" || echo "${@:3}" )

        do
            if [[ -n "$file" ]]

            then
                cp "$file" "$file.bak"

                mock_for_command $1 $2 "$LOCAL/$file"

                if ! diff -q "$LOCAL/$file" "$LOCAL/$file.bak" > /dev/null

                then
                    files+=( "$file" )
                fi

                if [[ -f "$LOCAL/$file.bak" ]]

                then
                    rm "$LOCAL/$file.bak"
                fi
            fi
        done

        if [[ ${#files[@]} -gt 0 ]]

        then
            git modify "${files[@]}"
        fi
    }

    function git
    {
        if [[ $1 == "add" ]] || [[ "$1" == "reset" && "$2" == "--soft" && $3 == "FLINT-TEMPORARY-COMMIT" && "$4" == "--quiet" ]]

        then
            files=$( [[ $1 == "add" ]] && echo "${@:2}" || echo "$( ls "$LOCAL/.git/committed/$3" )" )

            directory=$( [[ $1 == "add" ]] && echo "modified" || echo "committed/$3" )

            for file in $files

            do
                if [[ -n "$file" ]]

                then
                    if [[ -f "$LOCAL/.git/$directory/$file" ]]

                    then
                        mv "$LOCAL/.git/$directory/$file" "$LOCAL/.git/staged/$file"
                    else
                        cp "$LOCAL/$file" "$LOCAL/.git/staged/$file"
                    fi

                    local suffix=1

                    local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )

                    while [[ -f $cache ]]

                    do
                        (( suffix++ ))

                        cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )
                    done

                    cp "$LOCAL/.git/staged/$file" "$cache"
                fi
            done
        fi

        if [[ $1 == "modify" ]] || [[ $1 == "restore" && $2 == "--staged" ]]

        then
            files=$( [[ $1 == "modify" ]] && echo "${@:2}" || echo "${@:3}" )

            for file in $files

            do
                if [[ -n "$file" ]]

                then
                    if [[ $1 == "restore" && -f "$LOCAL/.git/staged/$file" ]]

                    then
                        mv "$LOCAL/.git/staged/$file" "$LOCAL/$file"
                    fi

                    cp "$LOCAL/$file" "$LOCAL/.git/modified/$file"

                    local suffix=1

                    local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/modified" "$file" "$suffix" )

                    while [[ -f $cache ]]

                    do
                        (( suffix++ ))

                        cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/modified" "$file" "$suffix" )
                    done

                    cp "$LOCAL/.git/modified/$file" "$cache"
                fi
            done
        fi

        if [[ $1 == "commit" && $2 == "-m" && -n $3 ]]

        then
            mkdir -p "$LOCAL/.git/committed/$3"

            for file in $( ls "$LOCAL/.git/staged" )

            do
                if [[ -f "$LOCAL/.git/staged/$file" ]]

                then
                    mv "$LOCAL/.git/staged/$file" "$LOCAL/.git/committed/$3/$file"
                fi
            done

            for file in $( ls "$LOCAL/.git/committed/$3" )

            do
                local suffix=1

                local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )

                while [[ -f $cache ]]

                do
                    (( suffix++ ))

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )
                done

                cp "$LOCAL/.git/committed/$3/$file" "$cache"
            done

            echo $3 >> "$LOCAL/.git/commits"
        fi

        if [[ $1 == "push" ]]

        then
            for directory in $( ls -d "$LOCAL/.git/committed"/* )

            do
                for file in $( ls "$directory" )

                do
                    cp "$directory/$file" "$REMOTE/$file"
                done
            done
        fi

        if [[ $1 == "pull" ]]

        then
            for file in $( ls "$REMOTE" )

            do
                cp "$REMOTE/$file" "$LOCAL/$file"
            done

            echo $4 >> "$LOCAL/.git/commits"
        fi

        if [[ $1 == "checkout" ]]

        then
            mv "$2"/* "$LOCAL"
        fi

        if [[ $1 == "hash-object" && $2 == '-w' && $3 == '--stdin' ]]

        then
            files=();

            while IFS= read -r line; do files+=( "$line" ); done

            for file in $files

            do
                mv "$LOCAL/.git/modified/$file" "$LOCAL/.git/patched/$file"

                if [[ -f "$REMOTE/$file" ]]

                then
                    cp "$REMOTE/$file" "$LOCAL/$file"
                fi

                if [[ -f "$LOCAL/.git/staged/$file" ]]

                then
                    cp "$LOCAL/.git/staged/$file" "$LOCAL/$file"
                fi

                local suffix=1

                local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/patched" "$file" "$suffix" )

                while [[ -f $cache ]]

                do
                    (( suffix++ ))

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/patched" "$file" "$suffix" )
                done

                cp "$LOCAL/.git/patched/$file" "$cache"
            done

            echo "patched"
        fi

        if [[ $1 == 'stash' ]]

        then
            if [[ -f "$LOCAL/.git/modified/$file" ]]

            then
                rm "$LOCAL/.git/modified/$file"
            fi
        fi

        if [[ $1 == "cat-file" && $2 == "-p" && -n $3 ]]

        then
            ls "$LOCAL/.git/$3"
        fi

        if [[ $1 == "apply" ]]

        then
            files=();

            while IFS= read -r line; do files+=( "$line" ); done

            for file in "${files[@]}"

            do
                if [[ -f "$LOCAL/.git/patched/$file" ]]

                then
                    cp "$LOCAL/.git/patched/$file" "$LOCAL/.git/modified/$file"

                    mv "$LOCAL/.git/patched/$file" "$LOCAL/$file"
                fi
            done
        fi




        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" && $4 == "--grep=FLINT-TEMPORARY-COMMIT" && $5 == "--max-count=1" ]]

        then
            if [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-TEMPORARY-COMMIT" ]]

            then
                echo "FLINT-TEMPORARY-COMMIT"
            fi
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $3 == "FLINT-TEMPORARY-COMMIT" && $4 == "--quiet" ]]

        then
            sed -i.bak -e "\$s|FLINT-TEMPORARY-COMMIT|DELETED-TEMPORARY-COMMIT|" "$LOCAL/.git/commits"
        fi

        if [[ $1 == "ls-tree" && $2 == "-r" && $3 == "HEAD" && $4 == "--long" ]]

        then
            for file in $( ls "$LOCAL" )

            do
                echo "100644 $(wc "$file" | tr -s " " | sed "s/^ //" )"
            done
        fi



        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            directory="$( ls -R "$LOCAL/.git/committed" )"

            current=""

            while IFS= read -r line

            do
                if [[ "$line" == *: ]]

                then
                    current="${line%:}"
                fi

                if [[ "$line" != *: && -n "$line" && -f "$current/$line" ]]

                then
                    echo "$line"
                fi
            done <<< "$directory"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then ls "$REMOTE"

        elif [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]] || [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then ls "$LOCAL/.git/staged"

        elif [[ $1 == "diff" && $2 == "--name-only" ]] || [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && -z $4 ]]

        then ls "$LOCAL/.git/modified"

        elif [[ $1 == "diff" && -n "$2" ]]

        then echo "${@:2}"

        fi




        echo $@ >> "$LOCAL/.git/commands"
    }
}

function unmock
{
    LOCAL=$1

    unset -f git

    unset -f eval_for_command

    unset -f wrap

    unset -f flint

    [[ -n "$LOCAL" && -d "$LOCAL/.git" ]] && rm -r "$LOCAL/.git"
}
