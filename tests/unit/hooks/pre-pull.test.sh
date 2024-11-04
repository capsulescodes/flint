beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/pre-pull" "$TEST/.flint/hooks/pre-pull"

    cp "$PWD/tests/fixtures/config.005.json" "$TEST/flint.config.json"

    source "$PWD/src/functions.sh"

    cd "$TEST" > /dev/null || exit 1

    export FLINT_CONFIG="$TEST/flint.config.json"

    export FLINT_HOOKS="$TEST/.flint/hooks"
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
}


mock()
{
    HEAD="$1"
    DIFF=($2)
    COMMANDS="$3"

    git()
    {
        if [[ "$1" == "rev-list" ]] && [[ "$2" == "HEAD" ]] && [[ "$3" == "--invert-grep" ]]

        then
            echo "$HEAD"
        fi

        if [[ "$1" == "reset" ]] && [[ "$2" == "--soft" ]]

        then
            echo "Mock : git reset --soft $3"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]] && [[ "$3" == "--name-only" ]] && [[ "$4" == "--diff-filter=ACMR" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi


        if [[ -f "$COMMANDS" ]]

        then
            echo "$@" >> "$COMMANDS"
        fi
    }
}

unmock()
{
    unset -f git
}




it_resets_to_last_manual_commit()
{
    mock "foo"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit when it exists"

    unmock
}


it_handles_no_manual_commit()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo "$output" | grep -qv "git reset"
    assert "Should not reset when no manual commit exists"

    unmock
}


it_runs_formatter_when_staged_files_exist()
{
    mock "bar" "file.001.js file.002.js"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft bar"
    echo "$output" | grep -q "remote_js_lint file.001.js file.002.js"
    assert "Should run formatter for staged files"

    unmock
}


it_handles_manual_commit_but_no_staged_files()
{
    mock "baz"

    output=$( source "$TEST/.flint/hooks/pre-pull" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft baz"
    echo "$output" | grep -qv "remote_js_lint"
    assert "Should reset but not run formatter when no staged files exist"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "qux" "file.001.js file.002.js" "$commands"

    ( source "$TEST/.flint/hooks/pre-pull" > /dev/null 2>&1 )
    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( cat "$commands" )" =~ "diff --cached --name-only --diff-filter=ACMR" ]]

    assert "Should use correct reset command format"

    unmock

    rm "$commands"
}
