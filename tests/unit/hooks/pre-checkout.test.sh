beforeAll()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core/hooks"

    cp "$PWD/hooks/pre-checkout" "$TEST/.core/hooks/pre-checkout"


    cd $TEST > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}


mock()
{
    STATE=$1
    RESET=($2)
    COMMANDS=$3

    git()
    {
        if [[ $1 == "ls-tree" && $2 == "-r" && $3 == "HEAD" && $4 == "--long" ]]

        then
            printf "%s\n" "$STATE"
        fi

        if [[ $1 == "diff" && $2 == "--staged" && $3 == "--name-only" ]]

        then
            printf "%s\n" "${RESET[@]}"
        fi


        if [[ $1 == "restore" && $2 == "--staged" ]]

        then
            echo "Mock : git restore --staged ${@:3}"
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




it_exports_state_if_state_exists()
{
    mock "1 foo bar 2 file.001.foo\n3 baz qux 4 file.002.foo"

    source "$TEST/.core/hooks/pre-checkout" > /dev/null
    [[ -n $FLINT_STATE ]]
    assert "Should export state"
    echo $FLINT_STATE | grep -q "1 foo bar 2 file.001.foo"
    assert "Should list file"
    echo $FLINT_STATE | grep -q "3 baz qux 4 file.002.foo"
    assert "Should list files"
}


it_restores_staged_files_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    output=$( source "$TEST/.core/hooks/pre-checkout" )
    echo $output | grep -q "Mock : git restore --staged file.001.foo file.002.foo"
    assert "Should restore staged files"

    unmock
}


it_exports_staged_files_if_staged_files_exist()
{
    mock "" "file.001.foo file.002.foo"

    source "$TEST/.core/hooks/pre-checkout" > /dev/null
    [[ -n $FLINT_STAGED_FILES ]]
    assert "Should export staged files"
    echo $FLINT_STAGED_FILES | grep -q "file.001.foo file.002.foo"
    assert "Should list staged files"
}


it_uses_correct_git_commands()
{
    commands=$( mktemp )

    mock "1 foo bar 1 file.001.foo\n1 foo baz 1 file.002.foo" "file.003.foo" $commands

    source "$TEST/.core/hooks/pre-checkout" > /dev/null
    [[ "$( head -n 1 "$commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 2 "$commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 3 "$commands" | tail -n 1 )" == "restore --staged file.003.foo" ]]
    assert "Should use correct staged command"
    [[ "$( head -n 4 "$commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "Should use correct ls-tree command"

    unmock

    [[ -f "$commands" ]] && rm $commands
}
