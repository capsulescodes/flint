source "$PWD/tests/helpers.sh"




for file in tests/**/*.test.sh

do
    source "$file"

    functions=( $( grep -Eo '^[[:space:]]*[^#[:space:]]+[[:space:]]*\(\)' "$file" | awk '{print $1}' | sed 's/()//' ) )


    tests=()
    results=0


    for function in "${functions[@]}"

    do
        if [[ "$function" == it_* ]] || [[ "$function" == test_* ]]

        then
            tests+=( "$function" )
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

            results+=$?
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




    run "$results" "$file"


    for function in "${functions[@]}"

    do
        unset -f $function
    done
done
