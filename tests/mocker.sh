function mock
{
    LOCAL=$1
    REMOTE=$2

    mkdir "$LOCAL/.git"

    mkdir "$LOCAL/.git/modified"
    mkdir "$LOCAL/.git/staged"
    mkdir "$LOCAL/.git/committed"

    touch "$LOCAL/.git/commits"
    touch "$LOCAL/.git/commands"


    function flint
    {
        source "$LOCAL/.core/bin/flint" $@
    }

    function wrap
    {
        [[ -f "$LOCAL/.flint/git.sh" ]] && source "$LOCAL/.flint/git.sh" $@ || git $@
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
                    if [[ -f "$LOCAL/.git/staged/$file" ]]

                    then
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




        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" && $4 == "--grep=FLINT-TEMPORARY-COMMIT" && $5 == "--max-count=1" ]]

        then
            if [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-TEMPORARY-COMMIT" ]]

            then
                echo "FLINT-TEMPORARY-COMMIT"
            fi
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && $3 == "FLINT-TEMPORARY-COMMIT" && "$4" == "--quiet" ]]

        then
            sed -i "" "\$s|FLINT-TEMPORARY-COMMIT|DELETED-TEMPORARY-COMMIT|" "$LOCAL/.git/commits"
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
