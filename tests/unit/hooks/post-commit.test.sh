beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/post-commit" "$TEST/.flint/hooks/post-commit"

    cp "$PWD/tests/fixtures/config.004.json" "$TEST/flint.config.json"

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
    FILTER=($2)
    COMMIT=$3
    COMMANDS=$4

    git()
    {
        if [[ $1 == "diff-tree" && $2 == "--diff-filter=d" && $3 == "--name-only" && $4 == "--no-commit-id" && $5 == "-r" && $6 == "HEAD" ]]

        then
            printf "%s\n" "${DIFF[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            printf "%s\n" "${FILTER[@]}"
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




it_skips_when_temp_commit()
{
    export FLINT_FIX_TEMP_COMMIT=1
#
    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    [ -z $output ]
    assert "Should skip execution when FLINT_FIX_TEMP_COMMIT is set"
#
    unset FLINT_FIX_TEMP_COMMIT
}


it_formats_committed_files()
{
    mock "file.001.js file.002.js" "file.001.js"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "local_js_lint file.001.js file.002.js"
    assert "Should run local lint command for committed files"

    unmock
}


it_adds_modified_files()
{
    mock "file.001.js file.002.js" "file.001.js"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.js"
    assert "Should add modified files"

    unmock
}


it_creates_temp_commit()
{
    mock "file.001.js file.002.js" "file.001.js" "foo"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "Mock : git commit -m foo"
    assert "Should create a temporary commit"

    unmock
}


it_handles_no_committed_files()
{
    mock

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    [ -z $output ]
    assert "Should not perform any actions when no files are committed"

    unmock
}


it_handles_no_modified_files_after_formatting()
{
    mock "file.001.js"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "local_js_lint file.001.js"
    assert "Should run formatter even if no files are modified afterwards"
    echo $output | grep -qv "git add"
    assert "Should not add files if none were modified after formatting"
    echo $output | grep -qv "git commit"
    assert "Should not create commit if no files were modified after formatting"

    unmock
}


it_identifies_modified_files()
{
    mock "file.001.js file_002.js file!char&003.js" "file.001.js file_002.js file!char&003.js"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.js file_002.js file!char&003.js"
    assert "Should add only modified files from committed files list"

    unmock
}


it_processes_multiple_files()
{
    mock "file.001.js file.002.js file.003.php" "file.001.js file.002.js"

    output=$( source "$TEST/.flint/hooks/post-commit" 2>&1 )
    echo $output | grep -q "local_js_lint file.001.js file.002.js"
    assert "Should process all committed files"
    echo $output | grep -q "Mock : git add file.001.js file.002.js"
    assert "Should add all modified files"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "file.001.js file.002.js" "file.001.js"

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should not be set before running the hook"

    ( source "$TEST/.flint/hooks/post-commit" > /dev/null 2>&1 )

    [ -z $FLINT_FIX_TEMP_COMMIT ]
    assert "FLINT_FIX_TEMP_COMMIT should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.js file.002.js file.003.php" "file.001.js file.002.js" "bar" $commands

    ( source "$TEST/.flint/hooks/post-commit" > /dev/null 2>&1 )
    [[ "$( cat $commands )" =~ "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "Should use correct diff-tree command format"
    [[ "$( cat $commands )" =~ "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( cat $commands )" =~ "add file.001.js file.002.js" ]]
    assert "Should use correct add command format"
    [[ "$( cat $commands )" =~ "commit -m" ]]
    assert "Should use correct commit command format"

    unmock

    rm $commands
}
