beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/pre-pull" "$TEST/.core/hooks/pre-pull"

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

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
    STAGED=($2)
    RESET=($3)
    HEAD=$4
    COMMANDS=$5

    count=$( mktemp )

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            if [[ -s $count && -n $RESET ]]

            then
                printf "%s\n" "${RESET[@]}"
            else
                printf "%s\n" "${STAGED[@]}"

                echo 1 >> $count
            fi
        fi

        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            printf "%s\n" "${UNSTAGED[@]}"
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

    rm $count
}




it_handles_no_manual_commits()
{
    mock

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "" "" "" "foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "" "" "" "bar"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_evals_unstaged_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo"
    assert "Should run remote lint command for staged files"

    unmock
}


it_evals_staged_files()
{
    mock "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo"
    assert "Should run remote lint command for staged files"

    unmock
}


it_evals_unstaged_and_staged_files()
{
    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo file.003.foo file.004.foo"
    assert "Should run formatter even if no files are modified afterwards"

    unmock
}


it_evals_sorted_files()
{
    mock "file.003.file file.002.foo file.001.foo" "file.002.foo file.003.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1 )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo file.003.foo"
    assert "Should run formatter even if no files are modified afterwards"

    unmock
}


it_sets_environment_variable_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" 2>&1; echo $FLINT_STAGED_FILES )
    echo $output | grep -q "remote_foo file.001.foo file.002.foo"
    assert "Should run formatter even if no files are modified afterwards"
    echo $output | grep -q "file.001.foo file.002.foo"
    assert "Should list staged files"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo" "file.002.foo" "" "bar" $commands

    ( source "$TEST/.core/hooks/pre-pull" > /dev/null 2>&1 )
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff-filter command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "reset --soft bar --quiet" ]]
    assert "Should use correct reset command format"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff-filter command format"

    unmock

    rm $commands
}
