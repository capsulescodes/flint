beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core"

    cp "$PWD/dist/run.sh" "$TEST/.core/run.sh"

    cp "$PWD/src/functions.sh" "$TEST/.core/functions.sh"

    cp "$PWD/tests/fixtures/echo" "$TEST/.core/echo"

    cp "$PWD/tests/fixtures/config.003.json" "$TEST/flint.config.json"

    sed -i.bak -e "s|source \"\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/../src/functions.sh\"||" "$TEST/.core/run.sh"

    mkdir -p "$TEST/.flint"

    echo 'config="flint.config.json"' > "$TEST/.flint/git.sh"


    cd $TEST > /dev/null || exit 1

    source "$TEST/.core/functions.sh"

    export FLINT_CONFIG="$TEST/flint.config.json"

    INIT_CWD=$TEST
}

afterAll()
{
    unset FLINT_CONFIG

    cd - > /dev/null || exit 1

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}


mock()
{
    UNSTAGED=($1)
    STAGED=($2)
    MODIFIED=($3)
    RESET=($4)
    PATCH=$5
    HEAD=$6
    COMMIT=$7
    COMMANDS=$8

    git()
    {
        if [[ $1 == "diff" && $2 == "--name-only" ]]

        then
            printf "%s\n" "${UNSTAGED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == 'hash-object' && $2 == '-w' && $3 == '--stdin' ]]

        then
            echo $PATCH
        fi

        if [[ $1 == 'stash' && $2 == 'push' && $3 == '--' && -n $4 ]]

        then
            echo "Mock : git stash push -- ${@:4}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${MODIFIED[@]}"
        fi

        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
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
            echo "Mock : git restore --staged ${@:3}"
        fi

        if [[ $1 == "commit" && $2 == "-m" ]]

        then
            echo "Mock : git commit -m $COMMIT"
        fi

        if [[ $1 == "apply" ]]

        then
            echo "Mock : git apply"
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




it_exits_if_destination_does_not_exist()
{
    mv "$TEST/.flint" "$TEST/bak"

    output=$( bash "$TEST/.core/run.sh" )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output message when .flint directory does not exist"

    mv "$TEST/bak" "$TEST/.flint"
}


it_exits_if_git_file_does_not_exist()
{
    mv "$TEST/.flint/git.sh" "$TEST/.flint/git.sh.bak"

    output=$( bash "$TEST/.core/run.sh" )
    echo $output | grep -q "Flint must be configured first"
    assert "Should output message when .flint directory does not exist"

    mv "$TEST/.flint/git.sh.bak" "$TEST/.flint/git.sh"
}


it_exits_if_config_file_does_not_exist()
{
    echo 'config="foo"' > "$TEST/.flint/git.sh"

    output=$( bash "$TEST/.core/run.sh" )
    echo $output | grep -q "The 'foo' file does not exist in the root directory."
    assert "Should output message when config file does not exist"

    echo 'config="flint.config.json"' > "$TEST/.flint/git.sh"
}


it_patches_files_when_matching_modified_and_staged_files()
{
    mock "file.001.foo file.003.foo" "file.001.foo file.002.foo file.003.foo" "" "foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git stash push -- file.001.foo file.003.foo"
    assert "Should restore files"

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
    mock "" "" "" "" "" "bar"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git reset --soft bar"
    assert "Should reset to last manual commit"

    unmock
}


it_resets_silently()
{
    mock "" "" "" "" "" "baz"

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
    mock "" "" "file.001.foo file.002.foo" "" "" "" "corge"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add newly modified files before"

    unmock
}


it_does_not_add_unstaged_modified_files_before()
{
    mock "file.001.foo file.002.foo" "" "file.002.foo file.003.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.003.foo"
    assert "Should not add already modified files before"

    unmock
}


it_adds_unmodified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo" "file.003.foo file.004.foo" "file.002.foo file.006.foo" "file.006.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.006.foo"
    assert "Should add modified files before"
    echo $output | grep -q "Mock : git add file.003.foo file.004.foo"
    assert "Should add modified staged files after"

    unmock
}


it_adds_modified_previous_staged_files_after()
{
    mock "file.001.foo file.002.foo file.004.foo" "file.003.foo file.004.foo" "file.002.foo file.004.foo file.006.foo" "file.006.foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.006.foo"
    assert "Should add modified files before"
    echo $output | grep -q "Mock : git add file.003.foo file.004.foo"
    assert "Should add modified staged files after"

    unmock
}


it_adds_staged_files_after_while_no_modified_files()
{
    mock "" "file.001.foo file.002.foo" "" "" "" "" "" "quux"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add files after"

    unmock
}


it_creates_commit_with_correct_message()
{
    mock "" "" "file.001.foo file.002.foo" "file.001.foo file.002.foo" "" "" "qux"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git add file.001.foo file.002.foo"
    assert "Should add modified files"
    echo $output | grep -q "Mock : git commit -m qux"
    assert "Should commit modified files with the correct message"

    unmock
}


it_sets_and_unsets_state_variables()
{
    mock "" "" "" "" "file.001.foo file.002.foo" "" "" "qux"

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should not be set before running the hook"

    source "$TEST/.core/run.sh" > /dev/null

    [ -z $FLINT_TEMPORARY_COMMIT ]
    assert "FLINT_TEMPORARY_COMMIT should be unset after running the hook"

    unmock
}


it_applies_patch_and_eval_if_patched_files()
{
    mock "file.001.foo file.002.foo" "file.002.foo file.003.foo" "" "" "foo"

    output=$( source "$TEST/.core/run.sh" )
    echo $output | grep -q "Mock : git apply"
    assert "Should apply patch"
    echo $output | grep -q "local_foo file.002.foo"
    assert "Should eval unpatched files"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "file.001.foo file.002.foo file.003.foo" "file.003.foo file.004.foo" "file.002.foo file.006.foo" "file.006.foo" "grault" "garply" "" $commands

    source "$TEST/.core/run.sh" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" ==  "diff --name-only" ]]
    assert "Should use correct unstaged command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" ==  "diff --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" ==  "diff file.003.foo" ]]
    assert "Should use correct diff command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "Should use correct hash-object command"
    [[ "$( head -n 5 "$commands" | tail -n 1 )" == "stash push -- file.003.foo" ]]
    assert "Should use correct stash command"
    [[ "$( head -n 6 "$commands" | tail -n 1 )" ==  "restore --staged file.003.foo file.004.foo" ]]
    assert "Should use correct restore command"
    [[ "$( head -n 7 "$commands" | tail -n 1 )" ==  "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "Should use correct rev-list command"
    [[ "$( head -n 8 "$commands" | tail -n 1 )" ==  "reset --soft garply --quiet" ]]
    assert "Should use correct reset command"
    [[ "$( head -n 9 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --name-only" ]]
    assert "Should use correct modified command"
    [[ "$( head -n 10 "$commands" | tail -n 1 )" ==  "add file.006.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 11 "$commands" | tail -n 1 )" ==  "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 12 "$commands" | tail -n 1 )" ==  "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "Should use correct commit command"
    [[ "$( head -n 13 "$commands" | tail -n 1 )" ==  "add file.003.foo file.004.foo" ]]
    assert "Should use correct add command"
    [[ "$( head -n 14 "$commands" | tail -n 1 )" == "cat-file -p grault" ]]
    assert "Should use correct cat-file command"
    [[ "$( head -n 15 "$commands" | tail -n 1 )" == "apply" ]]
    assert "Should use correct apply command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
