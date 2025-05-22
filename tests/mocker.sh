function mock
{
    LOCAL=$1
    REMOTE=$2

    mkdir -p "$LOCAL/.git"

    mkdir -p "$LOCAL/.git/modified"
    mkdir -p "$LOCAL/.git/staged"
    mkdir -p "$LOCAL/.git/committed"
    mkdir -p "$LOCAL/.git/stashed"

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
            if [[ -n $file ]]

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
        if [[ $1 == "modify" ]] || [[ $1 == "restore" && $2 == "--staged" ]]

        then
            files=$( [[ $1 == "modify" ]] && echo "${@:2}" || echo "${@:3}" )

            for file in $files

            do
                if [[ -n $file ]]

                then
                    if [[ $1 == "restore" && $2 == "--staged" && -f "$LOCAL/.git/staged/$file" ]]

                    then
                        cp "$LOCAL/.git/staged/$file" "$LOCAL/$file"

                        rm "$LOCAL/.git/staged/$file"
                    fi

                    if [[ -f "$LOCAL/.git/committed/$file" ]]

                    then
                        rm "$LOCAL/.git/committed/$file"
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


        if [[ $1 == "add" ]] || [[ "$1" == "reset" && "$2" == "--soft" && $3 == "FLINT-TEMPORARY-COMMIT" && "$4" == "--quiet" ]]

        then
            files=$( [[ $1 == "add" ]] && echo "${@:2}" || echo "$( ls "$LOCAL/.git/committed/" )" )

            directory=$( [[ $1 == "add" ]] && echo "modified" || echo "committed" )

            for file in $files

            do
                if [[ -n $file ]]

                then
                    if [[ -f "$LOCAL/.git/$directory/$file" ]]

                    then
                        rm "$LOCAL/.git/$directory/$file"
                    fi

                    cp "$LOCAL/$file" "$LOCAL/.git/staged/$file"

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

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            for file in $( ls "$LOCAL/.git/staged" )

            do
                if [[ -f "$LOCAL/.git/staged/$file" ]]

                then
                    mv "$LOCAL/.git/staged/$file" "$LOCAL/.git/committed/$file"
                fi
            done

            for file in $( ls "$LOCAL/.git/committed" )

            do
                local suffix=1

                local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )

                while [[ -f $cache ]]

                do
                    (( suffix++ ))

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )
                done

                cp "$LOCAL/.git/committed/$file" "$cache"
            done

            echo $3 >> "$LOCAL/.git/commits"
        fi

        if [[ $1 == "push" ]]

        then
            for file in $( ls -A "$LOCAL/.git/committed" )

            do
                cp "$LOCAL/.git/committed/$file" "$REMOTE/$file"
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

        if [[ $1 == "stash" ]]

        then
            if [[ $2 == "create" && $3 == "--keep-index" ]]

            then
                dir=$( mktemp -d )

                files=$( echo "${@:5}" )

                for file in $files

                do
                    if [[ -n $file ]]

                    then
                        if [[ -f "$LOCAL/.git/modified/$file" ]]

                        then
                            mv "$LOCAL/.git/modified/$file" "$dir/$file"
                        fi
                    fi
                done

                echo "$dir"
            fi

            if [[ $2 == "store" && $3 == "--quiet" && -n "$4" ]]

            then
                files=$( ls "$4" )

                for file in $files

                do
                    cp "$4/$file" "$LOCAL/.git/stashed/$file"

                    local suffix=1

                    local cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/stashed" "$file" "$suffix" )

                    while [[ -f $cache ]]

                    do
                        (( suffix++ ))

                        cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/stashed" "$file" "$suffix" )
                    done

                    cp "$LOCAL/.git/stashed/$file" "$cache"
                done
            fi

            if [[ $2 == "apply" && $3 == "--quiet" && -n "$4" ]]

            then
                mv "$LOCAL/.git/stashed"/* "$4"

                files=$( ls "$4" )

                for file in $files

                do
                    if [[ -n $file ]]

                    then
                        if [[ -f "$4/$file" ]]

                        then
                            cp "$4/$file" "$LOCAL/$file"

                            cp "$LOCAL/$file" "$LOCAL/.git/modified/$file"

                            rm "$4/$file"
                        fi
                    fi
                done
            fi

            if [[ $2 == "drop" && $3 == "--quiet" && -n "$4" ]]

            then
                rm -r "$4"
            fi
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




        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then
            ls "$REMOTE"
        fi

        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            ls "$LOCAL/.git/committed"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]] || [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            ls "$LOCAL/.git/staged"
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]] || [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && -z $4 ]]

        then
            ls "$LOCAL/.git/modified"
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
