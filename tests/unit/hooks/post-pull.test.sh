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
    cd - > /dev/null || exit 1

    rm -rf $TEST

    unset FLINT_CONFIG

    unset FLINT_HOOKS
}


mock()
{
    UNSTAGED=($1)
    RESET=($2)
    PULLED=($3)
    MODIFIED=($4)
    COMMIT=$5
    COMMANDS=$6

    count=$( mktemp )

    git()
    {
        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            if [[ -s $count ]]

            then
                printf "%s\n" "${MODIFIED[@]}"
            else
                printf "%s\n" "${UNSTAGED[@]}"

                echo 1 >> $count
            fi
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then
            printf "%s\n" "${PULLED[@]}"
        fi

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
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

    rm $count
}




it_handles_no_unstaged_no_staged_and_no_pulled_files()
{
    mock

    output=$( source "$TEST/.core/hooks/post-pull" )
    [[ -z $output ]]
    assert "Should not perform any actions when no files are pulled"

    unmock
}


it_evaluates_unstaged_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_evaluates_staged_files()
{
    mock "" "file.003.foo file.004.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.003.foo file.004.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_evaluates_pulled_files()
{
    mock "" "" "file.005.foo file.006.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.005.foo file.006.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_evaluates_sorted_files()
{
    mock "file.005.foo file.001.foo" "file.003.foo file.006.foo" "file.002.foo file.004.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo file.004.foo file.005.foo file.006.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_evaluates_unique_files()
{
    mock "file.001.foo file.002.foo" "file.002.foo file.003.foo" "file.003.foo file.004.foofile.004.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo file.004.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_handles_no_modified_files()
{
    mock "" "" "file.001.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -qv "git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_identifies_modified_files()
{
    mock "" "" "file.001.foo file_002.foo file!char003.foo" "file.001.foo file_002.foo file!char003.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file!char003.foo file.001.foo file_002.foo"
    assert "Should add only modified files from committed files list"

    unmock
}


it_adds_modified_files_before()
{
    mock "" "" "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"

    unmock
}


it_does_not_add_unstaged_modified_files_before()
{
    mock "file.001.foo file.002.foo" "" "" "file.001.foo file.002.foo"

    output=$( FLINT_UNSTAGED_FILES=$'file.001.foo\nfile.002.foo' source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -qv "Mock : git add"
    assert "Should not add already modified files before"

    unmock
}


it_adds_unmodified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.004.foo file.006.foo"

    output=$( FLINT_STAGED_FILES="file.001.foo file.002.foo" source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.004.foo file.006.foo"
    assert "Should add modified staged files after"
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified staged files after"

    unmock
}


it_adds_modified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.002.foo file.004.foo file.006.foo"

    output=$( FLINT_STAGED_FILES=$'file.001.foo\nfile.002.foo' source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git add file.004.foo file.006.foo"
    assert "Should add modified files before"
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified staged files after"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "" "" "file.001.foo file.002.foo" "file.001.foo" "foo"

    output=$( source "$TEST/.core/hooks/post-pull" )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create a temporary commit"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "" "" "file.002.foo file.003.foo" "file.002.foo"

    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    FLINT_UNSTAGED_FILES="foo"
    FLINT_STAGED_FILES="bar"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ -z $FLINT_TEMPORARY_COMMIT && -z $FLINT_STAGED_FILES && -z $FLINT_UNSTAGED_FILES ]]
    assert "variables should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.002.foo file.004.foo file.006.foo" "bar" $commands

    FLINT_UNSTAGED_FILES="file.002.foo"
    FLINT_STAGED_FILES="file.004.foo"

    source "$TEST/.core/hooks/post-pull" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "diff --diff-filter=d --name-only @{1} HEAD" ]]
    assert "Should use correct diff-filter command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "add file.006.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" =~ "commit -m" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" == "add file.004.foo" ]]
    assert "Should use correct add command"

    unmock

    rm $commands
}
