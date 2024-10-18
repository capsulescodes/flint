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
    git()
    {
        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]]

        then
            echo "file.001.js"
            echo "file.002.js"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" && "$3" == "--diff-filter=M" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add $2"
        fi

        if [[ "$1" == "rev-list" ]]

        then
            echo "foobar"
        fi

        if [[ "$1" == "reset" ]]

        then
            echo "Mock : git reset $2 $3"
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
    mock

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "remote_js_lint file.001.js file.002.js"
    assert "Should run remote lint command for staged files"

    unmock
}


it_adds_modified_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified files"

    unmock
}


it_resets_to_manual_commit()
{
    mock
    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foobar"
    assert "Should reset to last manual commit"

    unmock
}


it_handles_no_staged_files()
{
    git()
    {
        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    [ -z "$output" ]
    assert "Should not perform any actions when no files are staged"

    unmock
}


it_handles_no_modified_files_after_formatting()
{
    git()
    {
        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" && "$3" == "--diff-filter=M" ]]

        then
            echo ""
        fi
    }

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
    git()
    {
        if [[ "$1" == "diff" ]] && [[ "$2" == "--cached" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" && "$3" == "--diff-filter=M" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add $2"
        fi

        if [[ "$1" == "rev-list" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/pre-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified files even when no manual commit is found"
    echo "$output" | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}
