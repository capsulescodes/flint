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

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}


mock()
{
    RESET=($1)
    COMMIT=$2
    COMMANDS=$3

    git()
    {
        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
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




it_handles_no_current_staged_files_and_no_previous_staged_files()
{
    mock

    output=$( source "$TEST/.core/hooks/post-push" )
    [[ -z $output ]]
    assert "Should do nothing when no files are staged"
    echo $output | grep -qv "Mock : git add"
    assert "Should not add no previous staged files"

    unmock
}


it_handles_no_current_staged_files_but_previous_staged_files()
{
    mock

    output=$( FLINT_STAGED_FILES="file.001.foo file.002.foo" source "$TEST/.core/hooks/post-push" )
    echo $output | grep -qv "Mock : git commit"
    assert "Should not commit"
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add previous staged files"

    unmock
}


it_handles_current_staged_files_but_no_previous_staged_files()
{
    mock "file.001.foo file.002.foo" "foo"

    output=$( source "$TEST/.core/hooks/post-push" )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create temporary commit for staged files"
    echo $output | grep -qv "Mock : git add"
    assert "Should not add no previous staged files"

    unmock
}


it_handles_current_staged_files_and_previous_staged_files()
{
    mock "file.003.foo file.004.foo" "baz"

    output=$( FLINT_STAGED_FILES="file.001.foo file.002.foo" source "$TEST/.core/hooks/post-push" )
    echo $output | grep -q "Mock : git commit -m baz"
    assert "Should create temporary commit for staged files"
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add current staged files"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "file.001.foo" "qux"

    output=$( source "$TEST/.core/hooks/post-push" )
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should create commit with correct temporary commit message"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.foo" "quux"

    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    FLINT_STAGED_FILES="foo"

    source "$TEST/.core/hooks/post-push" > /dev/null
    [[ -z $FLINT_TEMPORARY_COMMIT && -z $FLINT_STAGED_FILES ]]
    assert "variables should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.003.foo file.004.foo" "" $commands

    FLINT_STAGED_FILES="file.001.foo file.002.foo"

    source "$TEST/.core/hooks/post-push" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "Should use correct add command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
