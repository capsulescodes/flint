assert()
{
    if [ $? -ne 0 ]

    then
        echo "\n\033[1;31mAssertion failed : $1.\033[0m\n"

        return 1
    fi

    return 0
}


test()
{
    $1

    if [ "$?" -eq 0 ]

    then
        echo "\033[1;32m\xE2\x9C\x94 \033[1;30m$1\033[0m"

        return 0
    else
            echo "\033[1;31m\xE2\x9C\x96 $1\033[0m"

        return 1
    fi
}


run()
{
    if [ $1 -eq 0 ]

    then
        echo "\n\033[1;32mTest file : $2 successful.\033[0m\n"

        return 0
    else
            echo "\n\033[1;31mTest file : $2 failing.\033[0m\n"

        return 1
    fi
}


summary()
{
    if (( $1 - $2 == 0 ))

    then
        echo "Tests: \033[1;32m $1 passed\n"

        return=0
    else
        echo "Tests: \033[1;31m $(( $1 - $2 )) failed\n"

        return=1
    fi
}
