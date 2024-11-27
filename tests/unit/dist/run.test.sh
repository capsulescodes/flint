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

    INIT_CWD=$TEST
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
        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            if [[ -s $first ]]

            then
                printf "%s\n" "${MODIFIED[@]}"
            else
                printf "%s\n" "${UNSTAGED[@]}"

                echo 1 >> $first
            fi
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && "$3" == "--staged" && $4 == "--name-only" ]]

        then
            if [[ -s $second ]]

            then
                printf "%s\n" "${RESET[@]}"
            else
                printf "%s\n" "${STAGED[@]}"

                echo 1 >> $second
            fi
        fi

        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
        fi

        if [[ $1 == "add" ]]

        then
            echo "Mock : git add ${@:2}"
        fi

        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            echo "Mock : git restore --staged $3"
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

    output=$( sh "$TEST/.core/run.sh" )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output message when .flint directory does not exist"

    mv "$TEST/bak" "$TEST/.flint"
}


it_exits_if_git_file_does_not_exist()
{
    mv "$TEST/.flint/git.sh" "$TEST/.flint/git.sh.bak"

    output=$( sh "$TEST/.core/run.sh" )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output message when .flint directory does not exist"

    mv "$TEST/.flint/git.sh.bak" "$TEST/.flint/git.sh"
}


it_exits_if_config_file_does_not_exist()
{
    echo 'config="foo"' > "$TEST/.flint/git.sh"

    output=$( sh "$TEST/.core/run.sh" )
    echo $output | grep -q "The 'foo' file does not exist in the root directory."
    assert "Should output message when config file does not exist"

    echo 'config="flint.config.json"' > "$TEST/.flint/git.sh"
}


it_handles_no_manual_commits()
{
    mock

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -qv "Mock : git reset"
    assert "Should not attempt to reset when no manual commit is found"

    unmock
}


it_resets_to_manual_commit()
{
    mock "" "" "" "" "bar"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git reset --soft bar"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "" "" "" "" "baz"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git reset --soft baz --quiet"
    assert "Should reset silently"

    unmock
}


it_evals_all_files()
{
    mock

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "local_foo ."
    assert "Should eval on current directory"

    unmock
}


it_restores_staged_files_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git restore --staged file.001.foo file.002.foo"
    assert "Should restore staged files"

    unmock
}


it_handles_no_modified_files()
{
    mock

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -qv "Mock : git add"
    assert "Should not add files when there are no modified files"

    unmock
}


it_adds_modified_files_before()
{
    mock "" "" "" "file.001.foo file.002.foo" "" "corge"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"

    unmock
}


it_does_not_add_unstaged_modified_files_before()
{
    mock "file.001.foo file.002.foo" "" "" "file.002.foo file.003.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.003.foo"
    assert "Should not add already modified files before"

    unmock
}


it_adds_unmodified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.002.foo file.006.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.006.foo"
    assert "Should add modified files before"
    echo $output | grep -q "Mock : git add file.003.foo file.004.foo"
    assert "Should add modified staged files after"

    unmock
}


it_adds_modified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo file.004.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.002.foo file.004.foo file.006.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.006.foo"
    assert "Should add modified files before"
    echo $output | grep -q "Mock : git add file.003.foo file.004.foo"
    assert "Should add modified staged files after"

    unmock
}


it_adds_staged_files_after_while_no_modified_files()
{
    mock "" "file.001.foo file.002.foo" "file.003.foo file.004.foo" "" "" "quux"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add files after"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "" "" "" "file.001.foo file.002.foo" "" "qux"

    output=$( source "$TEST/.core/run.sh" )
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

    source "$TEST/.core/run.sh" > /dev/null

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.005.foo file.006.foo" "file.002.foo file.006.foo" "grault" "" $commands

    source "$TEST/.core/run.sh" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" ==  "diff --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff staged command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" =~  "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" ==  "reset --soft grault --quiet" ]]
    assert "Should use correct reset command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" ==  "restore --staged file.003.foo file.004.foo" ]]
    assert "Should use correct restore command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff staged command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" ==  "diff --name-only" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 8 "$commands" | tail -n 1 )" ==  "add file.006.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 9 "$commands" | tail -n 1 )" =~  "commit -m" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 10 "$commands" | tail -n 1 )" ==  "add file.003.foo file.004.foo" ]]
    assert "Should use correct add command"

    unmock

    rm $commands
}
