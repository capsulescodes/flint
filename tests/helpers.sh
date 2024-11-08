assert()
{
    if [ $? -ne 0 ]

    then
        code=$1
    fi
}


test()
{
    code=""

    $1

    if [ -z "$code" ]

    then
        printf "\033[1;32m\xE2\x9C\x94\033[1;30m $1 \033[0m\n"

        return 0
    else
        printf "\033[1;31m\xE2\x9C\x96\033[1;30m $1 \033[0m-\033[1;31m $code \033[0m\n"

        return 1
    fi
}


run()
{
    if [ $1 -eq 0 ]

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
    else
        printf "\nTests: \033[1;31m $(( $1 - $2 )) failed\n\n"
    fi
}
