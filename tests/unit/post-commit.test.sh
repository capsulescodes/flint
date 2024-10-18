beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/post-commit" "$TEST/.flint/hooks/post-commit"

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

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
        if [[ "$1" == "diff-tree" ]]

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

        if [[ "$1" == "commit" ]]

        then
            echo "Mock : git commit $2 $3"
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

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    [ -z "$output" ]
    assert "Should skip execution when FLINT_FIX_TEMP_COMMIT is set"

    unset FLINT_FIX_TEMP_COMMIT
}

it_formats_committed_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo "$output" | grep -q "local_js_lint file.001.js file.002.js"
    assert "Should run local lint command for committed files"

    unmock
}

it_adds_modified_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified files"

    unmock
}

it_creates_temp_commit()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo "$output" | grep -q "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
    assert "Should create a temporary commit"

    unmock
}

it_handles_no_committed_files()
{
    git()
    {
        if [[ "$1" == "diff-tree" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    [ -z "$output" ]
    assert "Should not perform any actions when no files are committed"

    unmock
}

it_handles_no_modified_files_after_formatting()
{
    git()
    {
        if [[ "$1" == "diff-tree" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" && "$3" == "--diff-filter=M" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo "$output" | grep -q "local_js_lint file.001.js"
    assert "Should run formatter even if no files are modified afterwards"
    echo "$output" | grep -qv "git add"
    assert "Should not add files if none were modified after formatting"
    echo "$output" | grep -qv "git commit"
    assert "Should not create commit if no files were modified after formatting"

    unmock
}

it_sets_and_unsets_environment_variable()
{
    mock

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$TEST/.flint/hooks/post-commit" > /dev/null 2>&1 )

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}

it_processes_multiple_files_correctly()
{
    git()
    {
        if [[ "$1" == "diff-tree" ]]

        then
            echo "file.001.js"
            echo "file.002.js"
            echo "file.003.php"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" && "$3" == "--diff-filter=M" ]]

        then
            echo "file.001.js"
            echo "file.002.js"
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add $2 $3"
        fi

        if [[ "$1" == "commit" ]]

        then
            echo "Mock : git commit $2 $3"
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo "$output" | grep -q "local_js_lint file.001.js file.002.js"
    assert "Should process all committed files"
    echo "$output" | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add all modified files"

    unmock
}
