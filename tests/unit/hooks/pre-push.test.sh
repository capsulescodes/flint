beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/pre-push" "$TEST/.core/hooks/pre-push"

    cd $TEST > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}


mock()
{
    STAGED=($1)
    HEAD=$2
    COMMANDS=$3

    git()
    {
        if [[ $1 == "diff" && $2 == "--diff-filter=d" && $3 == "--staged" && $4 == "--name-only" ]]

        then
            printf "%s\n" "${STAGED[@]}"
        fi

        if [[ $1 == "rev-list" && $2 == "HEAD" && $3 == "--invert-grep" ]]

        then
            echo $HEAD
        fi

        if [[ $1 == "reset" && $2 == "--soft" && $4 == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
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




it_handles_no_manual_commits()
{
    mock

    output=$( source "$TEST/.core/hooks/pre-push" 2>&1 )
    echo $output | grep -qv "git reset"
    assert "Should do nothing when no manual commits are found"

    unmock
}


it_resets_to_last_manual_commit()
{
    mock "" "foo"

    output=$( source "$TEST/.core/hooks/pre-push" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft foo"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_resets_silently()
{
    mock "" "bar"

    output=$( source "$TEST/.core/hooks/pre-push" 2>&1 )
    echo $output | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_sets_environment_variable_if_staged_files_exist()
{
    mock "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-push" 2>&1; echo $FLINT_STAGED_FILES )
    echo $output | grep -q "file.001.foo file.002.foo"
    assert "Should list staged files"
    [ -n $FLINT_STAGED_FILES ]
    assert "FLINT_STAGED_FILES should be unset after running the hook"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "" "baz" $commands

    ( source "$TEST/.core/hooks/pre-push" > /dev/null 2>&1 )
    [[ "$( head -n 1 "$commands" | tail -n 1 )" =~ "diff --diff-filter=d --staged --name-only" ]]
    assert "Should use correct diff-filter command format"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "reset --soft baz --quiet" ]]
    assert "Should use correct reset command format"

    unmock

    rm $commands
}
