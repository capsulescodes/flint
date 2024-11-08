source "$PWD/tests/helpers.sh"




total=0

passed=0


for file in tests/**/**/*.test.sh

do
    source $file

    functions=( $( awk '/^[[:space:]]*[^#[:space:]]+[[:space:]]*\(\)/ && !/=/ {print $1}' $file | sed 's/()//' ) )


    tests=()

    results=0


    for function in "${functions[@]}"

    do
        if [[ $function == it_* ]] || [[ $function == test_* ]]

        then
            tests+=( $function )

            total=$(( total + 1 ))
        fi
    done




    if declare -f beforeAll > /dev/null

    then
        beforeAll
    fi




    for test in "${tests[@]}"

    do
        if declare -f beforeEach > /dev/null

        then
            beforeEach
        fi

        if declare -f $test > /dev/null

        then
            test $test

            result=$?

            results=$(( results + $result ))

            if [ $result -eq 0 ]

            then
                passed=$(( passed + 1 ))
            fi
        fi

        if declare -f afterEach > /dev/null

        then
            afterEach
        fi
    done




    if declare -f afterAll > /dev/null

    then
        afterAll
    fi



    run $results $file


    for function in "${functions[@]}"

    do
        unset -f $function
    done
done

summarize $total $passed
