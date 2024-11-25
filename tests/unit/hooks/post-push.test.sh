beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/post-push" "$TEST/.core/hooks/post-push"

    cd $TEST > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}


mock()
{
    STAGED=($1)
    COMMIT=$2
    COMMANDS=$3

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            echo "Mock : git restore --staged $3"
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
        fi

        if [[ $1 = "add" ]]

        then
            echo "Mock : git add ${@:2}"
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

    output=$( source "$TEST/.core/hooks/post-push" 2>&1 )
    [ -z $output ]
    assert "Should do nothing when no files are staged"

    unmock
}


it_handles_staged_files()
{
    mock "file.001.foo file.002.foo" "foo"

    output=$( source "$TEST/.core/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create temporary commit for staged files"

    unmock
}


it_handles_identical_current_and_previous_staged_files()
{
    mock "file.001.foo file.002.foo" "bar"

    output=$( FLINT_STAGED_FILES=$'file.001.foo\nfile.002.foo' source "$TEST/.core/hooks/post-push" 2>&1 )
    [[ -z $output ]]
    assert "Should do nothing when previous staged files are current staged files"

    unmock
}


it_handles_current_staged_files_and_previous_staged_files()
{
    mock "file.001.foo file.002.foo file.003.foo" "baz"

    output=$( FLINT_STAGED_FILES="file.002.foo file.003.foo" source "$TEST/.core/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git restore --staged file.002.foo file.003.foo"
    assert "Should restore current staged files"
    echo $output | grep -q "Mock : git commit -m baz"
    assert "Should create temporary commit for staged files"
    echo $output | grep -q "Mock : git add file.002.foo file.003.foo"
    assert "Should add current staged files"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "file.001.foo" "qux"

    output=$( source "$TEST/.core/hooks/post-push" 2>&1 )
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should create commit with correct temporary commit message"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.foo file.002.foo" "quux"

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    ( FLINT_STAGED_FILES="foo" source "$TEST/.core/hooks/post-push" > /dev/null 2>&1 )

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should be unset after running the hook"

    [ -z $FLINT_STAGED_FILES ]
    assert "FLINT_STAGED_FILES should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "" $commands

    ( FLINT_STAGED_FILES="file.002.foo file.003.foo" source "$TEST/.core/hooks/post-push" > /dev/null 2>&1 )
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "restore --staged file.002.foo file.003.foo" ]]
    assert "Should use correct commit command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" =~ "commit -m" ]]
    assert "Should use correct commit command format"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "add file.002.foo file.003.foo" ]]
    assert "Should use correct commit command format"

    unmock

    rm $commands
}
