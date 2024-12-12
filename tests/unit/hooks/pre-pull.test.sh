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
    unset FLINT_HOOKS

    unset FLINT_CONFIG

    cd - > /dev/null || exit 1

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}


mock()
{
    UNSTAGED=($1)
    STAGED=($2)
    RESET=($3)
    HEAD=$4
    COMMANDS=$5

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

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
        fi

        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            echo "Mock : git restore --staged ${@:3}"
        fi

        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
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


it_exports_unstaged_files_if_unstaged_files_exist()
{
    mock "file.001.foo file.002.foo"

    source "$TEST/.core/hooks/pre-pull" > /dev/null
    [[ -n $FLINT_UNSTAGED_FILES ]]
    assert "Should export unstaged files"
    echo $FLINT_UNSTAGED_FILES | grep -q "file.001.foo file.002.foo"
    assert "Should list unstaged files"
}


it_restores_staged_files_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -q "Mock : git restore --staged file.001.foo file.002.foo"
    assert "Should restore staged files"

    unmock
}


it_exports_staged_files_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    source "$TEST/.core/hooks/pre-pull" > /dev/null
    [[ -n $FLINT_STAGED_FILES ]]
    assert "Should export staged files"
    echo $FLINT_STAGED_FILES | grep -q "file.001.foo file.002.foo"
    assert "Should list staged files"
}


it_handles_no_manual_commits()
{
    mock

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_last_manual_commit_if_manual_commit_exists()
{
    mock "" "" "" "foo"

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_to_last_manual_commit_silently()
{
    mock "" "" "" "bar"

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_restores_reset_files_if_reset_files_exist()
{
    mock "" "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -q "Mock : git restore --staged file.001.foo file.002.foo"
    assert "Should restore reset files"

    unmock
}


it_evaluates_reset_files()
{
    mock "" "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-pull" )
    echo $output | grep -q "Mock : git restore --staged file.001.foo file.002.foo"
    assert "Should run remote eval command for staged files"
    echo $output | grep -q "remote_foo file.001.foo file.002.foo"
    assert "Should run remote eval command for staged files"

    unmock
}


it_exports_reset_files_if_reset_files_exist()
{
    mock "" "" "file.001.foo file.002.foo"

    source "$TEST/.core/hooks/pre-pull" > /dev/null
    [[ -n $FLINT_RESET_FILES ]]
    assert "Should export staged files"
    echo $FLINT_RESET_FILES | grep -q "file.001.foo file.002.foo"
    assert "Should list staged files"
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo" "file.002.foo" "file.003.foo" "bar" $commands

    source "$TEST/.core/hooks/pre-pull" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct unstaged command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "restore --staged file.002.foo" ]]
    assert "Should use correct restore command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "Should use correct rev-list command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "reset --soft bar --quiet" ]]
    assert "Should use correct reset command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" == "restore --staged file.003.foo" ]]
    assert "Should use correct restore command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
