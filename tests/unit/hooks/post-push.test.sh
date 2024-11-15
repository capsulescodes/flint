beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/post-push" "$TEST/.flint/hooks/post-push"

    cd $TEST > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}


mock()
{
    DIFF=($1)
    COMMIT=$2
    COMMANDS=$3

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
        fi


        if [[ -f "$COMMANDS" ]]

        then
            echo $@ >> $COMMANDS
        fi
    }
}

unmock()
{
    unset -f git
}




it_handles_no_staged_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo "$output"
    [ -z $output ]
    assert "Should do nothing when no files are staged"

    unmock
}


it_handles_staged_files()
{
    mock "file.001.foo file.002.foo" "foo"

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create temporary commit for staged files"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.foo file.002.foo" "bar"

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$TEST/.flint/hooks/post-push" > /dev/null 2>&1 )

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "file.001.foo" "baz"

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git commit -m baz"
    assert "Should create commit with correct temporary commit message"

    unmock
}


it_processes_multiple_staged_files()
{
    mock "file.001.foo file.002.foo file.003.bar" "qux"

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should handle multiple staged files correctly"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo file.003.bar" "quux" $commands

    ( source "$TEST/.flint/hooks/post-push" > /dev/null 2>&1 )
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" =~ "commit -m" ]]
    assert "Should use correct commit command format"

    unmock

    rm $commands
}
