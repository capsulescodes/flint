beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/post-pull" "$TEST/.flint/hooks/post-pull"

    cp "$PWD/tests/fixtures/config.003.json" "$TEST/flint.config.json"

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
    STAGED=($2)
    UNSTAGED=($3)
    MODIFIED=($4)
    COMMIT=$5
    COUNT=$6
    COMMANDS=$7

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "@{1}" && $5 == "HEAD" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

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

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
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




it_handles_no_pulled_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    [ -z $output ]
    assert "Should not perform any actions when no files are pulled"

    unmock
}


it_formats_pulled_files()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -q "local_foo_lint file.001.foo file.002.foo"
    assert "Should run local lint command for pulled files"

    unmock
}


it_handles_no_modified_files()
{
    mock "file.001.foo"

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -qv "git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_adds_newly_modified_files_before()
{
    count=$( mktemp )

    mock "file.001.foo file.002.foo" "" "" "file.001.foo file.002.foo" "" $count

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"

    unmock

    rm $count
}


it_does_not_add_already_modified_files_before()
{
    mock "file.001.foo file.002.foo file.003.foo" "" "file.003.foo" "file.003.foo" "" $count

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -qv "Mock : git add"
    assert "Should not add already modified files before"

    unmock
}


it_adds_modified_staged_files_after()
{
    count=$( mktemp )

    mock "file.001.foo file.002.foo file.003.foo" "file.003.foo" "" "file.003.foo" "" $count

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -q "Mock : git add file.003.foo"
    assert "Should add modified staged files after"

    unmock

    rm $count
}


it_identifies_modified_files()
{
    count=$( mktemp )

    mock "file.001.foo file_002.foo file!char&003.foo" "" "" "file.001.foo file_002.foo file!char&003.foo" "" $count

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo file_002.foo file!char&003.foo"
    assert "Should add only modified files from committed files list"

    unmock

    rm $count
}


it_creates_temp_commit()
{
    count=$( mktemp )

    mock "file.001.foo file.002.foo" "" "" "file.001.foo" "foo" $count

    output=$( source "$TEST/.flint/hooks/post-pull" 2>&1 )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create a temporary commit"

    unmock

    rm $count
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.foo file.002.foo" "file.001.foo"

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$TEST/.flint/hooks/post-pull" > /dev/null 2>&1 )

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    count=$( mktemp )

    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "" "" "file.001.foo" "bar" $count $commands

    ( source "$TEST/.flint/hooks/post-pull" > /dev/null 2>&1 )
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "diff --diff-filter=d --name-only @{1} HEAD" ]]
    assert "Should use correct diff-filter command format"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "Should use correct add command format"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" =~ "commit -m" ]]
    assert "Should use correct commit command format"

    unmock

    rm $commands

    rm $count
}
