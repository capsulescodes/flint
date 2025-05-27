beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/pre-commit" "$TEST/.core/hooks/pre-commit"

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

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
    UNSTAGED=($1)
    STAGED=($2)
    MODIFIED=($3)
    PATCH=$4
    HEAD=$5
    COMMANDS=$6

    git()
    {
        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            printf "%s\n" "${UNSTAGED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == 'hash-object' && $2 == '-w' && $3 == '--stdin' ]]

        then
            echo $PATCH
        fi

        if [[ $1 == 'stash' && $2 == 'push' && $3 == '--' && -n $4 ]]

        then
            echo "Mock : git stash push -- ${@:4}"
        fi

        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$4" == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${MODIFIED[@]}"
        fi

        if [[ $1 == "add" ]]

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




it_skips_when_temporary_commit()
{
    export FLINT_TEMPORARY_COMMIT=1

    output=$( source "$TEST/.core/hooks/pre-commit" )
    [[ -z $output ]]
    assert "Should skip execution when FLINT_TEMPORARY_COMMIT is set"

    unset FLINT_TEMPORARY_COMMIT
}


it_handles_no_manual_commits()
{
    mock "" "file.001.foo" "file.001.foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add modified files even when no manual commit is found"
    echo $output | grep -qv "Mock : git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_last_manual_commit_if_manual_commit_exists()
{
    mock "" "file.001.foo file.002.foo" "file.001.foo" "" "foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_to_last_manual_commit_silently()
{
    mock "" "file.001.foo file.002.foo" "file.001.foo" "" "bar"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_handles_no_reset_files()
{
    mock

    output=$( source "$TEST/.core/hooks/pre-commit" )
    [[ -z $output ]]
    assert "Should not perform any actions when no files are staged"

    unmock
}


it_evaluates_reset_files()
{
    mock "" "file.001.foo file.002.foo" "file.001.foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo"
    assert "Should run remote eval command for staged files"

    unmock
}


it_handles_no_modified_files()
{
    mock "" "file.001.foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "remote_foo file.001.foo"
    assert "Should run formatter even if no files are modified afterwards"
    echo $output | grep -qv "Mock : git add"
    assert "Should not add files if none were modified after formatting"
    echo $output | grep -qv "Mock : git reset"
    assert "Should not reset if no files were modified after formatting"

    unmock
}


it_adds_modified_files()
{
    mock "" "file.001.foo file_002.foo" "file.001.foo file_002.foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "Mock : git add file.001.foo file_002.foo"
    assert "Should add only modified files from committed files list"

    unmock
}


it_exports_reset_files_if_reset_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    source "$TEST/.core/hooks/pre-commit" > /dev/null
    [[ -n $FLINT_RESET_FILES ]]
    assert "FLINT_RESET_FILES should be set after running the hook"
    echo $FLINT_RESET_FILES | grep -q "file.001.foo file.002.foo"
    assert "Should list reset files"

    unset FLINT_RESET_FILES

    unmock
}


it_patches_files_when_matching_modified_and_staged_files()
{
    mock "file.001.foo file.003.foo" "file.001.foo file.002.foo file.003.foo" "" "foo"

    output=$( source "$TEST/.core/hooks/pre-commit" )
    echo $output | grep -q "Mock : git stash push -- file.001.foo file.003.foo"
    assert "Should restore files"

    unmock
}


it_exports_patch_if_patched_files()
{
    mock "file.001.foo" "file.001.foo" "" "foo"

    source "$TEST/.core/hooks/pre-commit" > /dev/null
    [[ -n $FLINT_PATCH ]]
    assert "FLINT_PATCH should be set after running the hook"
    echo $FLINT_PATCH | grep -q "foo"
    assert "Should list reset files"

    unset FLINT_PATCH

    unmock
}


it_does_not_patch_when_no_matching_modified_and_staged_files()
{
    mock "file.001.foo" "file.002.foo"

    source "$TEST/.core/hooks/pre-commit" > /dev/null
    [[ -z $FLINT_PATCH ]]
    assert "FLINT_PATCH should not be set after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.002.foo file.004.foo" "file.001.foo file.002.foo file.003.foo file.004.foo" "file.001.foo" "foo" "bar" $commands

    source "$TEST/.core/hooks/pre-commit" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct unstaged command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "diff file.002.foo file.004.foo" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "Should use correct hash-object command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "stash push -- file.002.foo file.004.foo" ]]
    assert "Should use correct stash command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "Should use correct rev-list command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" ==  "reset --soft bar --quiet" ]]
    assert "Should use correct reset command"
    [[ "$( head -n 8 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 9 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --name-only" ]]
    assert "Should use correct modified command"
    [[ "$( head -n 10 "$commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "Should use correct add command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
