todo()
{
   code=2
   message="${1:-TODO}"
}


assert()
{
    if [ $? -ne 0 ]

    then
        code=1
        message=$1
        line="${BASH_LINENO[0]}"
    else
        code=0
    fi
}


test()
{
    code=""
    message=""

    $1

    if [[ $code == 2 ]]

    then
        printf "\033[1;33m\xE2\x96\xB2\033[1;33m $1 \033[0m-\033[1;33m $message \033[0m\n"
    fi

    if [[ $code == 1 ]]

    then
        printf "\033[1;31m\xE2\x9C\x96\033[1;30m $1 \033[0m-\033[1;31m $message : at line $line \033[0m\n"

        return 1
    fi

    if [[ $code == 0 ]]

    then
        printf "\033[1;32m\xE2\x9C\x94\033[1;30m $1 \033[0m\n"

        return 0
    fi
}


run()
{
    if [[ $1 -eq 0 ]]

    then
        printf "\n\033[1;32mTest file : $2 successful.\033[0m\n\n"

        return 0
    else
        printf "\n\033[1;31mTest file : $2 failing.\033[0m\n\n"

        return 1
    fi
}


summarize()
{
    if (( $1 - $2 == 0 ))

    then
        printf "\nTests: \033[1;32m $1 passed\n\n"

        exit 0;
    else
        printf "\nTests: \033[1;31m $(( $1 - $2 )) failed\n\n"

        exit 1;
    fi
}
