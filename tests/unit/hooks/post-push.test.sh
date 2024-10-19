beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/post-push" "$TEST/.flint/hooks/post-push"

    cd "$TEST" > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}


mock()
{
    git()
    {
        if [[ "$1" == "diff" && "$2" =~ "--cached" && "$3" =~ "--name-only" ]]

        then
            echo "file.001.js"
            echo "file.002.js"
        fi

        if [[ "$1" == "commit" && "$2" == "-m" && "$3" == "FLINT-FIX-TEMP-COMMIT" ]]

        then
            echo "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
        fi
    }
}

unmock()
{
    unset -f git
}




it_handles_staged_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo "$output" | grep -q "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
    assert "Should create temporary commit for staged files"

    unmock
}

it_handles_no_staged_files()
{
    git()
    {
        if [[ "$1" == "diff" && "$2" =~ "--cached" && "$3" =~ "--name-only" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    [ -z "$output" ]
    assert "Should do nothing when no files are staged"

    unmock
}

it_sets_and_unsets_environment_variable()
{
    mock

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$TEST/.flint/hooks/post-push" > /dev/null 2>&1 )

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}

it_creates_commit_with_correct_message()
{
    commands=$( mktemp )

    git()
    {
       echo "$@" >> "$commands"

        if [[ "$1" == "diff" && "$2" =~ "--cached" && "$3" =~ "--name-only" ]]

        then
            echo "file.001.js"
        fi

        if [[ "$1" == "commit" ]]

        then
            echo "Mock : git commit $2 $3"
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )

    echo "$output" | grep -q "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
    assert "Should create commit with correct temporary commit message"

    [[ "$( cat "$commands" )" =~ "commit -m FLINT-FIX-TEMP-COMMIT" ]]
    assert "Should use correct commit command format"

    unmock
}

it_processes_multiple_staged_files()
{
    git()
    {
        if [[ "$1" == "diff" && "$2" =~ "--cached" && "$3" =~ "--name-only" ]]

        then
            echo "file.001.js"
            echo "file.002.js"
            echo "file.003.php"
        fi

        if [[ "$1" == "commit" ]]

        then
            echo "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
        fi
    }

    output=$( source "$TEST/.flint/hooks/post-push" 2>&1 )
    echo "$output" | grep -q "Mock : git commit -m FLINT-FIX-TEMP-COMMIT"
    assert "Should handle multiple staged files correctly"

    unmock
}
