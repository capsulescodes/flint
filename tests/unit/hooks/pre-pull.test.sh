beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/pre-pull" "$TEST/.flint/hooks/pre-pull"

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

    cp "$PWD/tests/fixtures/echo" "$TEST/echo"

    source "$PWD/src/functions.sh"

    cd $TEST > /dev/null || exit 1

    export FLINT_CONFIG="$TEST/flint.config.json"

    export FLINT_HOOKS="$TEST/.flint/hooks"
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
    DIFF=($1)
    FILTER=($2)
    HEAD=$3
    COMMANDS=$4

    git()
    {
        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            printf "%s\n" "${FILTER[@]}"
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




it_handles_no_manual_commits()
{
    mock "file.001.foo" "file.001.foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add modified files even when no manual commit is found"
    echo $output | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "file.001.foo file.002.foo" "file.001.foo" "foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "file.001.foo file.002.foo" "file.001.foo" "bar"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_handles_no_staged_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    [ -z $output ]
    assert "Should not perform any actions when no files are staged"

    unmock
}


it_formats_staged_files()
{
    mock "file.001.foo file.002.foo" "file.001.foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo_lint file.001.foo file.002.foo"
    assert "Should run remote lint command for staged files"

    unmock
}


it_handles_no_modified_files()
{
    mock "file.001.foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo_lint file.001.foo"
    assert "Should run formatter even if no files are modified afterwards"
    echo $output | grep -qv "git add"
    assert "Should not add files if none were modified after formatting"
    echo $output | grep -qv "git reset"
    assert "Should not reset if no files were modified after formatting"

    unmock
}


it_identifies_modified_files()
{
    mock "file.001.foo file_002.foo file!char&003.foo" "file.001.foo file_002.foo file!char&003.foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo file_002.foo file!char&003.foo"
    assert "Should add only modified files from committed files list"

    unmock
}


it_processes_multiple_files()
{
    mock "file.001.foo file.002.foo file.003.bar" "file.001.foo file.002.foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo_lint file.001.foo file.002.foo"
    assert "Should run formatter even if no files are modified afterwards"
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified files"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "file.001.foo" "bar" $commands

    ( source "$TEST/.flint/hooks/pre-pull" > /dev/null 2>&1 )

    [[ "$( head -n 1 "$commands" | tail -n 1 )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "reset --soft bar --quiet" ]]
    assert "Should use correct reset command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff-filter command format"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "Should use correct add command format"

    unmock

    rm $commands
}
