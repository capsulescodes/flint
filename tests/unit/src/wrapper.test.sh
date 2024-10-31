beforeAll()
{
    TEST=$( mktemp -d )

    INIT_CWD="$TEST" sh "$PWD/dist/init.sh" init --with-hooks > /dev/null

    cd "$TEST" > /dev/null || exit 1

    source .flint/git.sh > /dev/null
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}




it_checks_if_flint_hook()
{
    [[ -f "$PWD/$hooks/pre-commit" ]]
    assert "pre-commit should be recognized as a Flint hook"

    [[ -f "$PWD/$hooks/post-pull" ]]
    assert "post-pull should be recognized as a Flint hook"

    ! [[ -f "$PWD/$hooks/random-hook" ]]
    assert "random-hook should not be recognized as a Flint hook"
}


it_checks_if_config_file_exists()
{
    mv "$TEST/flint.config.json" "$TEST/flint.config.json.bak"

    output=$( bash .flint/git.sh commit 2>&1 )
    echo "$output" | grep -q "Warning : The \"flint.config.json\" file does not exist"
    assert "Should warn when flint.config.json is missing"

    mv "$TEST/flint.config.json.bak" "$TEST/flint.config.json"
}


it_can_run_pre_hook()
{
    echo "echo 'Pre-hook executed'" > .flint/hooks/pre-commit

    chmod +x .flint/hooks/pre-commit
    output=$( bash .flint/git.sh commit 2>&1 )
    echo "$output" | grep -q "Pre-hook executed"
    assert "Pre-commit hook should be executed"
}


it_can_run_post_hook()
{
    echo "echo 'Post-hook executed'" > .flint/hooks/post-commit

    chmod +x .flint/hooks/post-commit
    output=$(bash .flint/git.sh commit 2>&1)
    echo "$output" | grep -q "Post-hook executed"
    assert "Post-commit hook should be executed"
}
