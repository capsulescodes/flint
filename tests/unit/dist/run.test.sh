beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core"

    cp "$PWD/dist/run.sh" "$TEST/.core/run.sh"

    cp "$PWD/src/functions.sh" "$TEST/.core/functions.sh"

    cp "$PWD/tests/fixtures/echo" "$TEST/.core/echo"

    cp "$PWD/tests/fixtures/config.003.json" "$TEST/flint.config.json"

    sed -i "" "s|source \"\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/../src/functions.sh\"||" "$TEST/.core/run.sh"

    mkdir -p "$TEST/.flint"

    echo 'config="flint.config.json"' > "$TEST/.flint/git.sh"


    cd $TEST > /dev/null || exit 1

    source "$TEST/.core/functions.sh"

    export FLINT_CONFIG="$TEST/flint.config.json"
}

afterAll()
{
    cd - > /dev/null || exit 1

    unset FLINT_CONFIG

    rm -rf $TEST
}


mock()
{
    UNSTAGED=($1)
    STAGED=($2)
    RESET=($3)
    MODIFIED=($4)
    HEAD=$5
    COMMIT=$6
    COMMANDS=$7

    first=$( mktemp )
    second=$( mktemp )

    git()
    {
        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && "$3" == "--staged" && $4 == "--name-only" ]]

        then
            if [[ -s $first ]]

            then
                printf "%s\n" "${RESET[@]}"
            else
                printf "%s\n" "${STAGED[@]}"

                echo 1 >> $first
            fi
        fi

        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            if [[ -s $second ]]

            then
                printf "%s\n" "${MODIFIED[@]}"
            else
                printf "%s\n" "${UNSTAGED[@]}"

                echo 1 >> $second
            fi
        fi

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            echo "Mock : git restore ${@:3}"
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

    rm $first

    rm $second
}




it_exits_if_destination_does_not_exist()
{
    mv "$TEST/.flint" "$TEST/bak"

    output=$( INIT_CWD=$TEST sh "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output error message when .flint directory does not exist"

    mv "$TEST/bak" "$TEST/.flint"
}


it_exits_if_git_file_does_not_exist()
{
    mv "$TEST/.flint/git.sh" "$TEST/.flint/git.sh.bak"

    output=$( INIT_CWD=$TEST sh "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output error message when .flint directory does not exist"

    mv "$TEST/.flint/git.sh.bak" "$TEST/.flint/git.sh"
}


it_loads_config_if_destination_exists()
{
    mock "" "" "" "" "foo"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should call eval_for_command 'local' with the correct config value"

    unmock
}


it_handles_no_manual_commits()
{
    mock

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -qv "Mock : git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "" "" "" "" "bar"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft bar"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "" "" "" "" "baz"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft baz --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_formats_all_files()
{
    mock

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "local_foo ."
    assert "Should run formatter on current directory"

    unmock
}


it_adds_newly_modified_files_before()
{
    mock "" "" "" "file.001.foo file.002.foo" "" "corge"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"
    echo $output | grep -q "Mock : git commit -m corge"
    assert "Should use correct commit command format"

    unmock
}


it_does_not_add_already_modified_files_before()
{
    mock "file.001.foo" "" "" "file.001.foo file.002.foo"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.002.foo"
    assert "Should not add already modified files before"

    unmock
}


it_adds_staged_files_after_while_no_modified_files()
{
    mock "" "file.001.foo" "file.001.foo" "" "" "quux"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add files after"

    unmock
}


it_adds_staged_files_after_with_reset_file()
{
    mock "" "file.001.foo" "file.001.foo" "" "" "quux"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add files after"

    unmock
}


it_adds_staged_files_after_with_modified_file()
{
    mock "" "file.001.foo" "" "file.002.foo" "" "quux"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.002.foo"
    assert "Should not add already modified files before"
    echo $output | grep -q "Mock : git restore file.001.foo"
    assert "Should restore added files before"
    echo $output | grep -q "Mock : git commit -m quux"
    assert "Should use correct commit command format"
    echo $output | grep -q "Mock : git add file.001.foo"
    assert "Should add files after"

    unmock
}


it_handles_no_modified_files()
{
    mock

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -qv "Mock : git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_creates_temp_commit()
{
    mock "" "" "" "file.001.foo file.002.foo" "" "qux"

    output=$( INIT_CWD=$TEST source "$TEST/.core/run.sh" 2>&1 )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified files"
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should commit modified files with the correct message"

    unmock
}


it_sets_and_unsets_environment_variable()
{
    mock "" "" "" "file.001.foo file.002.foo" "" "qux"

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    ( INIT_CWD=$TEST source "$TEST/.core/run.sh" > /dev/null 2>&1 )

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "" "file.001.foo file.003.foo file.005.foo" "grault" "" $commands

    ( INIT_CWD=$TEST source "$TEST/.core/run.sh" > /dev/null 2>&1 )

    [[ "$( head -n 1 "$commands" | tail -n 1 )" ==  "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff staged command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" =~  "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" ==  "reset --soft grault --quiet" ]]
    assert "Should use correct reset command format"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff staged command format"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" ==  "diff --name-only" ]]
    assert "Should use correct diff command format"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" ==  "add file.005.foo" ]]
    assert "Should use correct add command format"
    [[ "$( head -n 8 "$commands" | tail -n 1 )" ==  "restore --staged file.003.foo file.004.foo" ]]
    assert "Should use correct restore command format"
    [[ "$( head -n 9 "$commands" | tail -n 1 )" =~  "commit -m" ]]
    assert "Should use correct commit command format"
    [[ "$( head -n 10 "$commands" | tail -n 1 )" ==  "add file.003.foo file.004.foo" ]]
    assert "Should use correct add command format"

    unmock

    rm $commands
}
