beforeAll()
{
    TEST=$( mktemp -d )

    mkdir -p "$TEST/.flint/hooks"

    cp "$PWD/hooks/pre-push" "$TEST/.flint/hooks/pre-push"

    cd "$TEST" > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}


mock()
{
    LIST="$1"
    COMMANDS="$2"

    git()
    {
        if [[ "$1" == "rev-list" && "$2" == "HEAD" && "$3" == "--invert-grep" ]]

        then
            printf "%s\n" "${LIST[@]}"
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$4" == "--quiet" ]]

        then
            echo "Mock : git reset --soft $3 --quiet"
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




it_handles_no_manual_commits()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    echo "$output" | grep -qv "git reset"
    assert "Should do nothing when no manual commits are found"

    unmock
}


it_resets_to_last_manual_commit()
{
    mock "foo"

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foo"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_resets_silently()
{
    mock "bar"

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft bar --quiet"
    assert "Should reset to the last non-temporary commit"

    unmock
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "baz" "$commands"

    ( source "$TEST/.flint/hooks/pre-push" > /dev/null 2>&1 )
    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep" ]]
    assert "Should use correct rev-list command format"
    [[ "$( cat "$commands" )" =~ "reset --soft" ]]
    assert "Should use correct reset command format"

    unmock

    rm "$commands"
}
