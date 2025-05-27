beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/post-commit" "$TEST/.core/hooks/post-commit"

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
    COMMITTED=($1)
    MODIFIED=($2)
    RESET=($3)
    COMMIT=$4
    COMMANDS=$5

    git()
    {
        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            printf "%s\n" "${COMMITTED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${MODIFIED[@]}"
        fi

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
        fi

        if [[ $1 == "cat-file" && $2 == "-p" && -n $3 ]]

        then
            echo "Mock : git cat-file -p ${@:3}"
        fi

        if [[ $1 == "apply" ]]

        then
            echo "Mock : git apply"
        fi


        if [[ -f $COMMANDS ]]

        then
            echo $@ >> $COMMANDS
        fi
    }
}

unmock()
{
    unset -f git
}




it_skips_when_temporary_commit()
{
    export FLINT_TEMPORARY_COMMIT=1

    output=$( source "$TEST/.core/hooks/post-commit" )
    [[ -z $output ]]
    assert "Should skip execution when FLINT_TEMPORARY_COMMIT is set"

    unset FLINT_TEMPORARY_COMMIT
}


it_handles_no_committed_and_reset_files()
{
    mock

    output=$( source "$TEST/.core/hooks/post-commit" )
    [[ -z $output ]]
    assert "Should not perform any actions when no files are committed"

    unmock
}


it_evaluates_committed_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_reset_files()
{
    mock

    output=$( FLINT_RESET_FILES="file.003.foo file.004.foo" source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "local_foo file.003.foo file.004.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_sorted_files()
{
    mock "file.004.foo file.001.foo"

    output=$( FLINT_RESET_FILES="file.003.foo file.002.foo" source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo file.004.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_evaluates_unique_files()
{
    mock "file.001.foo file.002.foo"

    output=$( FLINT_RESET_FILES="file.003.foo file.002.foo" source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "local_foo file.001.foo file.002.foo file.003.foo"
    assert "Should run local eval command for pulled files"

    unmock
}


it_handles_no_modified_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -qv "Mock : git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_adds_modified_files()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified files"

    unmock
}


it_handles_no_reset_files()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified files"
    echo $output | grep -qv "Mock : git commit"
    assert "Should not commit no reset files"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo" "file.001.foo file.002.foo" "foo"

    output=$( source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create commit with correct temporary commit message"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    source "$TEST/.core/hooks/post-commit" > /dev/null
    [[ -z $FLINT_TEMPORARY_COMMIT ]]
    assert "FLINT_TEMPORARY_COMMIT should be unset after running the hook"

    unmock
}


it_unsets_reset_files_if_reset_files_exist()
{
    mock

    FLINT_RESET_FILES="file.001.foo"

    source "$TEST/.core/hooks/post-commit" > /dev/null
    [[ -z $FLINT_RESET_FILES ]]
    assert "Should unset reset files"

    unmock
}


it_applies_patch_if_patch_exists()
{
    mock

    output=$( FLINT_PATCH="foo" source "$TEST/.core/hooks/post-commit" )
    echo $output | grep -q "Mock : git apply"
    assert "Should apply patch"

    unmock
}


it_unsets_patch_if_patch_exists()
{
    mock

    FLINT_PATCH="foo"

    source "$TEST/.core/hooks/post-commit" > /dev/null
    [[ -z $FLINT_PATCH ]]
    assert "Should unset patch"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    FLINT_PATCH="bar"

    mock "file.001.foo file.002.foo" "file.001.foo file.002.foo" "file.001.foo file.002.foo" "baz" $commands

    source "$TEST/.core/hooks/post-commit" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" ==  "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "Should use correct diff-tree command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" ==  "add file.001.foo file.002.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" == "cat-file -p bar" ]]
    assert "Should use correct cat-file command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" == "apply" ]]
    assert "Should use correct apply command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
