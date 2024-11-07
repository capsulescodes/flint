beforeAll()
{
    TEST=$( mktemp -d )

    path=$PWD

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

    cp "$PWD/tests/fixtures/echo" "$TEST/echo"

    source "$PWD/src/functions.sh"

    cd "$TEST" > /dev/null || exit 1

    export FLINT_CONFIG="$TEST/flint.config.json"
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"

    unset FLINT_CONFIG
}


mock()
{
    DIFF=($1)
    HEAD="$2"
    COMMIT="$3"
    COMMANDS="$4"

    git()
    {
        if [[ "$1" == "rev-list" ]] && [[ "$2" == "HEAD" ]] && [[ "$3" == "--invert-grep" ]]

        then
            echo "$HEAD"
        fi

        if [[ "$1" == "reset" ]] && [[ "$2" == "--soft" ]] && [[ "$4" == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ "$1" == "diff" ]] && [[ "$2" == "--name-only" ]] && [[ "$3" == "--diff-filter=M" ]]

        then
            printf "%s " "${DIFF[@]}"
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ "$1" == "commit" ]] && [[ "$2" == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
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




it_prevents_double_initialization()
{
    INIT_CWD="$TEST" sh "$path/dist/run.sh" > /dev/null
    [ "$?" -eq 0 ]
    assert "Should exit cleanly when INIT_CWD equals PWD"
}


it_handles_no_manual_commits()
{
    mock "file.001.js file.002.js"

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -qv "git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "file.001.js file.002.js" "foo"

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foo"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "file.001.js file.002.js" "bar"

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_formats_all_files()
{
    mock

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "local_js_lint ."
    assert "Should run formatter on current directory"

    unmock
}


it_adds_modified_files()
{
    mock "file.001.js file.002.js"
#
    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add modified files"
#
    unmock
}


it_handles_no_modified_files()
{
    mock "" "qux"

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -qv "git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_commits_modified_files()
{
    mock "file.001.js file.002.js" "" "baz"

    output=$( source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add modified files"
    echo "$output" | grep -q "Mock : git commit -m baz"
    assert "Should commit modified files with the correct message"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.js file.002.js"

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$path/dist/run.sh" > /dev/null 2>&1 )

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.js file.002.js" "quux" "corge" "$commands"

    ( source "$path/dist/run.sh" > /dev/null 2>&1 )

    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( cat "$commands" )" =~ "reset --soft quux --quiet" ]]
    assert "Should use correct reset command format"
    [[ "$( cat "$commands" )" =~ "diff --name-only --diff-filter=M" ]]
    assert "Should use correct diff command format"
    [[ "$( cat "$commands" )" =~ "add file.001.js file.002.js" ]]
    assert "Should use correct add command format"
    [[ "$( cat "$commands" )" =~ "commit -m" ]]
    assert "Should use correct commit command format"

    unmock

    rm "$commands"
}
