mock()
{
    LOCAL=$1
    REMOTE=$2

    flint()
    {
        [[ -f "$LOCAL/.flint/git.sh" ]] && source "$LOCAL/.flint/git.sh" || git "$@"
    }


    git()
    {
        if [[ $1 == "add" ]]

        then
            for file in ${@:2}

            do
                if [[ -n "$file" ]]

                then
                    if [[ ! -d "$LOCAL/.git/staged" ]]

                    then
                        mkdir "$LOCAL/.git/staged"
                    fi

                    cp "$file" "$LOCAL/.git/staged"

                    suffix=1

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )

                    while [ -e "$cache" ]

                    do
                        (( suffix++ ))

                        cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )
                    done

                    cp "$file" "$cache"
                fi
            done
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            if [[ ! -d "$LOCAL/.git/committed" ]]

            then
                mkdir "$LOCAL/.git/committed"
            fi

            mv "$LOCAL/.git/staged/"[^.]* "$LOCAL/.git/committed/"

            for file in $( ls "$LOCAL/.git/committed" )

            do
                suffix=1

                cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )

                while [ -e "$cache" ]

                do
                    (( suffix++ ))

                    cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )
                done

                cp "$file" "$cache"
            done

            echo $3 >> "$LOCAL/.git/commits"
        fi

        if [[ $1 == "push" ]]

        then
            mv "$LOCAL/.git/committed"/.[!.]* "$REMOTE"
        fi




        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo "$( tail -n 1 "$LOCAL/.git/commits" )"
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$4" == "--quiet" ]]

        then
            if [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-FIX-TEMP-COMMIT" ]]

            then
                mv "$LOCAL/.git/committed/"[^.]* "$LOCAL/.git/staged/"

                sed -i "" "\$s|FLINT-FIX-TEMP-COMMIT|DELETED-TEMP-COMMIT|" "$LOCAL/.git/commits"
            fi
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            [[ -d "$LOCAL/.git/staged" ]] && echo "$( ls "$LOCAL/.git/staged" )" || echo ""
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            echo "$( ls "$LOCAL" )"
        fi

        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            [[ -d "$LOCAL/.git/committed" ]] && echo "$( ls "$LOCAL/.git/committed" )" || echo ""
        fi




        echo $@ >> "$LOCAL/.git/commands"
    }
}

unmock()
{
    unset -f flint

    unset -f git
}


# mock()
# {
#     flint()
#     {
#         [[ -f "$LOCAL/.flint/git.sh" ]] && source "$LOCAL/.flint/git.sh" || git "$@"
#     }


#     git()
#     {
#         if [[ $1 == "add" ]]

#         then
#             for file in "${@:2}"

#             do
#                 if [[ -n "$file" ]]

#                 then
#                     if [[ ! -d "$LOCAL/.git/staged" ]]

#                     then
#                         mkdir "$LOCAL/.git/staged"
#                     fi

#                     cp "$file" "$LOCAL/.git/staged"

#                     suffix=1

#                     cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )

#                     while [ -e "$cache" ]

#                     do
#                         (( suffix++ ))

#                         cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/staged" "$file" "$suffix" )
#                     done

#                     cp "$file" "$cache"
#                 fi
#             done
#         fi

#         if [[ $1 == "commit" && $2 == "-m" ]]

#         then
#             if [[ ! -d "$LOCAL/.git/committed" ]]

#             then
#                 mkdir "$LOCAL/.git/committed"
#             fi

#             mv "$LOCAL/.git/staged/"[^.]* "$LOCAL/.git/committed/"

#             for file in "$( ls "$LOCAL/.git/committed" )"

#             do
#                 suffix=1

#                 cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )

#                 while [ -e "$cache" ]

#                 do
#                     (( suffix++ ))

#                     cache=$( printf "%s/.%s.%03d" "$LOCAL/.git/committed" "$file" "$suffix" )
#                 done

#                 cp "$file" "$cache"
#             done

#             echo $3 >> "$LOCAL/.git/commits"
#         fi

#         if [[ $1 == "push" ]]

#         then
#             mv "$LOCAL/.git/committed"/.[!.]* "$REMOTE"
#         fi




#         if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

#         then
#             echo "$( tail -n 1 "$LOCAL/.git/commits" )"
#         fi

#         if [[ "$1" == "reset" && "$2" == "--soft" && "$4" == "--quiet" ]]

#         then
#             if [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-FIX-TEMP-COMMIT" ]]

#             then
#                 mv "$LOCAL/.git/committed/"[^.]* "$LOCAL/.git/staged/"

#                 sed -i "" "\$s|FLINT-FIX-TEMP-COMMIT|DELETED-TEMP-COMMIT|" "$LOCAL/.git/commits"
#             fi
#         fi

#         if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

#         then
#             echo "$( ls "$LOCAL/.git/staged" )"
#         fi

#         if [[ $1 == "diff" && $2 == "--name-only" ]]

#         then
#             echo "$( ls "$LOCAL" )"
#         fi

#         if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

#         then
#             echo "$( ls "$LOCAL/.git/committed" )"
#         fi




#         echo $@ >> "$LOCAL/.git/commands"
#     }
# }
