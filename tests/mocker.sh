function mock
{
    LOCAL=$1
    REMOTE=$2

    function flint
    {
        [[ -f "$LOCAL/.flint/git.sh" ]] && source "$LOCAL/.flint/git.sh" || git "$@"
    }

    function eval_for_local
    {
        files=()

        for file in ${@:2}

        do
            if [[ -n "$file" ]]

            then
                cp "$file" "$file.bak"

                mock_for_local $1 "$LOCAL/$file"

                if ! diff -q "$LOCAL/$file" "$LOCAL/$file.bak" > /dev/null

                then
                    files+=( "$file" )
                fi

                rm "$LOCAL/$file.bak"
            fi
        done

        git modify "${files[@]}"
    }

    function eval_for_remote
    {
        files=()

        for file in ${@:2}

        do
            if [[ -n "$file" ]]

            then
                cp "$LOCAL/$file" "$LOCAL/$file.bak"

                mock_for_remote $1 "$LOCAL/$file"

                if ! diff -q "$LOCAL/$file" "$LOCAL/$file.bak" > /dev/null

                then
                    files+=( "$file" )
                fi

                rm "$LOCAL/$file.bak"
            fi
        done

        git modify "${files[@]}"
    }

    function git
    {
        if [[ $1 == "modify" ]]

        then
            for file in ${@:2}

            do
                if [[ -f "$LOCAL/.git/staged/$file" ]]

                then
                    rm "$LOCAL/.git/staged/$file"
                fi

                mkdir -p "$LOCAL/.git/modified"

                cp "$LOCAL/$file" "$LOCAL/.git/modified/$file"

                suffix=1

                cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/modified" "$file" "$suffix" )

                while [ -f "$cache" ]

                do
                    (( suffix++ ))

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/modified" "$file" "$suffix" )
                done

                cp "$LOCAL/.git/modified/$file" "$cache"
            done
        fi

        if [[ $1 == "add" ]]

        then
            for file in ${@:2}

            do
                if [[ -n "$file" ]]

                then
                    if [[ -f "$LOCAL/.git/modified/$file" ]]

                    then
                        rm "$LOCAL/.git/modified/$file"
                    fi

                    mkdir -p "$LOCAL/.git/staged"

                    cp "$LOCAL/$file" "$LOCAL/.git/staged/$file"

                    suffix=1

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )

                    while [ -f "$cache" ]

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
            mkdir -p "$LOCAL/.git/committed"

            mv "$LOCAL/.git/staged/"[^.]* "$LOCAL/.git/committed/"

            for file in $( ls "$LOCAL/.git/committed" )

            do
                suffix=1

                cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )

                while [ -f "$cache" ]

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
            cp "$LOCAL/.git/committed"/.[!.]* "$REMOTE"
        fi

        if [[ $1 == "pull" ]]

        then
            cp "$REMOTE"/[^.]* "$LOCAL"

            echo $4 >> "$LOCAL/.git/commits"
        fi




        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" && $4 == "--grep=FLINT-TEMPORARY-COMMIT" && $5 == "--max-count=1" ]]

        then
            [[ -f "$LOCAL/.git/commits" && "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-TEMPORARY-COMMIT" ]] && echo "FLINT-TEMPORARY-COMMIT" || echo ""
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && $3 == "FLINT-TEMPORARY-COMMIT" && "$4" == "--quiet" ]]

        then
            for file in $( ls "$LOCAL/.git/committed/" )

            do
                if [[ -f "$LOCAL/.git/committed/$file" ]]

                then
                    mv "$LOCAL/.git/committed/$file" "$LOCAL/.git/staged/$file"
                fi
            done

            sed -i "" "\$s|FLINT-TEMPORARY-COMMIT|DELETED-TEMPORARY-COMMIT|" "$LOCAL/.git/commits"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            [[ -d "$LOCAL/.git/staged" ]] && ls "$LOCAL/.git/staged" || echo ""
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            [[ -d "$LOCAL/.git/modified" ]] && ls "$LOCAL/.git/modified" || echo ""
        fi

        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            [[ -d "$LOCAL/.git/committed" ]] && ls "$LOCAL/.git/committed" || echo ""
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then
            ls "$REMOTE"
        fi

        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            for file in ${@:3}

            do
                if [[ -f "$LOCAL/.git/staged/$file" ]]

                then
                    mv "$LOCAL/.git/staged/$file" "$LOCAL/$file"
                fi
            done
        fi

        echo $@ >> "$LOCAL/.git/commands"
    }
}

function unmock
{
    unset -f flint

    unset -f eval_for_local

    unset -f eval_for_remote

    unset -f git
}
