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
    git()
    {
        if [[ "$1" == "rev-list" && "$@" =~ "--invert-grep" && "$@" =~ "--grep=FLINT-FIX-TEMP-COMMIT" ]]

        then
            echo "foobar"
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$3" == "foobar" ]]

        then
            echo "Mock : git reset --soft foobar"
        fi
    }
}

unmock()
{
    unset -f git
}




it_resets_to_last_manual_commit()
{
    mock

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft foobar"
    assert "Should reset to the last non-temporary commit"

    unmock
}

it_handles_no_manual_commits()
{
    git()
    {
        if [[ "$1" == "rev-list" && "$@" =~ "--invert-grep" && "$@" =~ "--grep=FLINT-FIX-TEMP-COMMIT" ]]

        then
            echo ""
        fi
    }

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    [ -z "$output" ]
    assert "Should do nothing when no manual commits are found"

    unmock
}

it_correctly_identifies_temp_commits()
{
    git()
    {
        if [[ "$1" == "rev-list" && "$@" =~ "--invert-grep" && "$@" =~ "--grep=FLINT-FIX-TEMP-COMMIT" && "$@" =~ "--max-count=1" ]]

        then
            echo "bazqux"
        fi

        if [[ "$1" == "reset" && "$2" == "--soft" && "$3" == "bazqux" ]]

        then
            echo "Mock : git reset --soft bazqux"
        fi
    }

    output=$( source "$TEST/.flint/hooks/pre-push" 2>&1 )
    echo "$output" | grep -q "Mock : git reset --soft bazqux"
    assert "Should correctly identify and reset to last manual commit"

    unmock
}

it_uses_correct_git_commands()
{
    commands=$( mktemp )

    git()
    {
        echo "$@" >> "$commands"

        if [[ "$1" == "rev-list" && "$@" =~ "--invert-grep" && "$@" =~ "--grep=FLINT-FIX-TEMP-COMMIT" ]]

        then
            echo "quuxcorge"
        fi

        if [[ "$1" == "reset" ]]

        then
            echo "Mock : git reset $2 $3"
        fi
    }

    ( source "$TEST/.flint/hooks/pre-push" > /dev/null 2>&1 )
    # commands=
    [[ "$( cat "$commands" )" =~ "rev-list HEAD --invert-grep --grep=FLINT-FIX-TEMP-COMMIT --max-count=1" ]]
    assert "Should use correct rev-list command format"

    [[ "$( cat "$commands" )" =~ "reset --soft" ]]
    assert "Should use correct reset command format"

    rm "$commands"
    unmock
}
