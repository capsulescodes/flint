beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/pre-commit" "$TEST/.flint/hooks/pre-commit"

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
    DIFF=($1)
    FILTER=($2)
    HEAD="$3"
    COMMANDS="$4"

    git()
    {
        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]] && [[ "$3" == "--name-only" ]] && [[ "$4" == "--diff-filter=ACMR" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" ]] && [[ "$3" == "--diff-filter=M" ]]

        then
            printf "%s\n" "${FILTER[@]}"
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ "$1" == "rev-list" ]] && [[ "$2" == "HEAD" ]] && [[ "$3" == "--invert-grep" ]]

        then
            echo "$HEAD"
        fi

        if [[ "$1" == "reset" ]] && [[ "$2" == "--soft" ]]

        then
            echo "Mock : git reset --soft $3"
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




it_skips_when_temp_commit()
{
    export FLINT_FIX_TEMP_COMMIT=1

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    [ -z "$output" ]
    assert "Should skip execution when FLINT_FIX_TEMP_COMMIT is set"

    unset FLINT_FIX_TEMP_COMMIT
}


it_formats_staged_files()
{
    mock "file.001.js file.002.js" "file.001.js"

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "remote_js_lint file.001.js file.002.js"
    assert "Should run remote lint command for staged files"

    unmock
}


it_adds_modified_files()
{
    mock "file.001.js file.002.js" "file.001.js"

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified files"

    unmock
}


it_resets_to_manual_commit()
{
    mock "file.001.js file.002.js" "file.001.js" "foo"

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_handles_no_staged_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    [ -z "$output" ]
    assert "Should not perform any actions when no files are staged"

    unmock
}


it_handles_no_modified_files_after_formatting()
{
    mock "file.001.js"

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "remote_js_lint file.001.js"
    assert "Should run formatter even if no files are modified afterwards"
    echo "$output" | grep -qv "git add"
    assert "Should not add files if none were modified after formatting"
    echo "$output" | grep -qv "git reset"
    assert "Should not reset if no files were modified after formatting"

    unmock
}


it_handles_no_manual_commits()
{
    mock "file.001.js" "file.001.js"

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified files even when no manual commit is found"
    echo "$output" | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.js file.002.js" "file.001.js" "bar" "$commands"

    ( source "$TEST/.flint/hooks/pre-commit" > /dev/null 2>&1 )
    [[ "$( cat "$commands" )" =~ "diff --cached --name-only --diff-filter=ACMR" ]]
    assert "Should use correct diff-filter command format"
    [[ "$( cat "$commands" )" =~ "diff --name-only --diff-filter=M" ]]
    assert "Should use correct diff command format"
    [[ "$( cat "$commands" )" =~ "add file.001.js" ]]
    assert "Should use correct add command format"
    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct add command format"
    [[ "$( cat "$commands" )" =~ "reset --soft bar" ]]
    assert "Should use correct add command format"

    unmock

    rm "$commands"
}
