beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/post-pull" "$TEST/.core/hooks/post-pull"

    cp "$PWD/tests/fixtures/config.003.json" "$TEST/flint.config.json"

    cp "$PWD/tests/fixtures/echo" "$TEST/.core/echo"

    source "$PWD/src/functions.sh"


    cd $TEST > /dev/null || exit 1

    export FLINT_CONFIG="$TEST/flint.config.json"

    export FLINT_HOOKS="$TEST/.core/hooks"
}

afterAll()
{
    unset FLINT_HOOKS

    unset FLINT_CONFIG

    cd - > /dev/null || exit 1

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}


mock()
{
    PULLED=($1)
    MODIFIED=($2)
    RESET=($3)
    COMMIT=$4
    COMMANDS=$5

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then
            printf "%s\n" "${PULLED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${MODIFIED[@]}"
        fi

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
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




it_handles_no_pulled_and_reset_files()
{
    mock

    output=$( source "$TEST/.core/hooks/post-pull" )
    [[ -z $output ]]
    assert "Should not perform any actions when no files are pulled"

    unmock
}


it_evaluates_pulled_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_reset_files()
{
    mock

    output=$( FLINT_RESET_FILES="file.003.foo file.004.foo" source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.003.foo file.004.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_sorted_files()
{
    mock "file.004.foo file.001.foo"

    output=$( FLINT_RESET_FILES="file.003.foo file.002.foo" source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo file.004.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_unique_files()
{
    mock "file.001.foo file.002.foo"

    output=$( FLINT_RESET_FILES="file.003.foo file.002.foo" source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_handles_no_modified_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -qv "git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_adds_modified_files()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"

    unmock
}


it_handles_no_reset_files()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add modified files"
    echo $output | grep -qv "Mock : git commit"
    assert "Should not commit no reset files"

    unmock
}


it_commits_with_correct_message_if_reset_files_exist()
{
    mock "file.001.foo" "file.001.foo" "file.001.foo" "qux"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should create commit with correct temporary commit message"

    unmock
}


it_exports_and_unsets_temporary_commit()
{
    mock "file.001.foo" "quux"

    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "variables should be unset after running the hook"

    unmock
}


it_unsets_reset_files_if_reset_files_exist()
{
    mock

    FLINT_RESET_FILES="file.001.foo"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ -z $FLINT_RESET_FILES ]]
    assert "Should unset reset files"

    unmock
}


it_adds_staged_files()
{
    mock

    output=$( FLINT_STAGED_FILES="file.001.foo file.002.foo" source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified staged files after"

    unmock
}


it_unsets_staged_files_if_staged_files_exist()
{
    mock

    FLINT_STAGED_FILES="file.001.foo"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ -z $FLINT_STAGED_FILES ]]
    assert "Should unset staged files"

    unmock
}


it_unsets_unstaged_files_if_unstaged_files_exist()
{
    mock

    FLINT_UNSTAGED_FILES="file.001.foo"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ -z $FLINT_UNSTAGED_FILES ]]
    assert "Should unset staged files"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "file.001.foo file.003.foo" "file.001.foo" "bar" $commands

    FLINT_UNSTAGED_FILES="file.002.foo"
    FLINT_STAGED_FILES="file.004.foo"
    FLINT_RESET_FILES="file.003.foo"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --diff-filter=d --name-only @{1} HEAD" ]]
    assert "Should use correct diff-filter command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "add file.001.foo file.003.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" == "add file.004.foo" ]]
    assert "Should use correct add command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
