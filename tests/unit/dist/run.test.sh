beforeAll()
{
    TEST=$( mktemp -d )

    path=$PWD

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

    cp "$PWD/tests/fixtures/echo" "$TEST/echo"

    source "$PWD/src/functions.sh"

    mkdir -p "$TEST/.flint"

    echo 'config="flint.config.json"' > "$TEST/.flint/git.sh"

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
    STAGED=($1)
    UNSTAGED=($2)
    MODIFIED=($3)
    HEAD="$4"
    COMMIT="$5"
    COUNT="$6"
    COMMANDS="$7"

    git()
    {
        if [[ "$1" == "rev-list" && "$2" == "HEAD" && "$3" == "--invert-grep" ]]

        then
            echo "$HEAD"
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$4" == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ "$1" == "diff" && "$2" == "--staged" && "$3" == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ "$1" == "diff" && "$2" == "--name-only" ]]

        then
            if [[ -f "$COUNT" ]]

            then
                if [[ -z "$( < "$COUNT" )" ]]

                then
                    printf "%s\n" "${UNSTAGED[@]}"
                else
                    printf "%s\n" "${MODIFIED[@]}"
                fi

                echo 1 >> $COUNT
            else
                printf "%s\n" "${UNSTAGED[@]}"
            fi
        fi

        if [[ "$1" == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ "$1" == "commit" && "$2" == "-m" ]]

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


it_exits_if_destination_does_not_exist()
{
    mv "$TEST/.flint" "$TEST/bak"

    output=$( INIT_CWD="$TEST" PWD="$path" sh "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Flint must be configured first"
    assert "Should output error message when .flint directory does not exist"

    mv "$TEST/bak" "$TEST/.flint"
}


it_exits_if_git_file_does_not_exist()
{
    mv "$TEST/.flint/git.sh" "$TEST/.flint/git.sh.bak"

    output=$( INIT_CWD="$TEST" PWD="$path" sh "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Flint must be configured first"
    assert "Should output error message when .flint directory does not exist"

    mv "$TEST/.flint/git.sh.bak" "$TEST/.flint/git.sh"
}


it_loads_config_if_destination_exists()
{
    mock "" "" "" "foo"

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foo"
    assert "Should call format_for_local with the correct config value"

    unmock
}


it_handles_no_manual_commits()
{
    mock

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -qv "Mock : git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "" "" "" "bar"

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft bar"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "" "" "" "baz"

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft baz --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_formats_all_files()
{
    mock

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "local_js_lint ."
    assert "Should run formatter on current directory"

    unmock
}


it_adds_newly_modified_files_before()
{
    count=$( mktemp )

    mock "" "" "file.001.js file.002.js" "" "" $count

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add newly modified files before"

    unmock

    rm $count
}


it_does_not_add_already_modified_files_before()
{
    mock "" "file.001.js" "file.001.js file.002.js"

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -qv "Mock : git add"
    assert "Should not add already modified files before"

    unmock
}


it_adds_modified_staged_files_after()
{
    count=$( mktemp )

    mock "file.001.js file.002.js" "" "file.001.js" "" "" $count

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js"
    assert "Should add modified staged files after"

    unmock

    rm $count
}


it_handles_no_modified_files()
{
    mock

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -qv "Mock : git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_creates_temp_commit()
{
    count=$( mktemp )

    mock "" "" "file.001.js file.002.js" "" "qux" $count

    output=$( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" 2>&1 )
    echo "$output" | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add modified files"
    echo "$output" | grep -q "Mock : git commit -m qux"
    assert "Should commit modified files with the correct message"

    unmock

    rm $count
}


it_sets_and_unsets_environment_variable()
{
    count=$( mktemp )

    mock "" "" "file.001.js file.002.js" "" "qux" $count

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" > /dev/null 2>&1 )

    [ -z "$FLINT_FIX_TEMP_COMMIT" ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock

    rm $count
}


it_uses_correct_git_commands()
{
    count=$( mktemp )

    commands=$( mktemp )

    mock "file.001.js file.002.js" "file.003.js file.004.js" "file.001.js file.003.js file.005.js" "quux" "corge" $count $commands

    ( INIT_CWD="$TEST" PWD="$path" source "$path/dist/run.sh" > /dev/null 2>&1 )

    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( cat "$commands" )" =~ "reset --soft quux --quiet" ]]
    assert "Should use correct reset command format"
    [[ "$( cat "$commands" )" =~ "diff --staged --name-only" ]]
    assert "Should use correct diff staged command format"
    [[ "$( cat "$commands" )" =~ "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( cat "$commands" )" =~ "add file.005.js" ]]
    assert "Should use correct add command format"
    [[ "$( cat "$commands" )" =~ "commit -m" ]]
    assert "Should use correct commit command format"
    [[ "$( cat "$commands" )" =~ "add file.001.js" ]]
    assert "Should use correct add command format"

    unmock

    rm $commands

    rm $count
}
