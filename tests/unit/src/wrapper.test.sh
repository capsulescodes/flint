beforeAll()
{
    TEST=$( mktemp -d )


    mkdir "$TEST/.core"

    cp "$PWD/src/wrapper.sh" "$TEST/.core/wrapper.sh"

    cp "$PWD/stubs/config.json" "$TEST/flint.config.json"

    sed -i.bak -e $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$TEST/.core/wrapper.sh"

    sed -i.bak -e "s|command git \"\$@\"|echo \"git\"|" "$TEST/.core/wrapper.sh"


    cd $TEST > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}




it_checks_if_config_file_exists()
{
    output=$( config="foo" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "'foo' file not found"
    assert "Should warn when flint.config.json is missing"
}


it_runs_pre_hook()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Pre-hook executed'" > "$TEST/.flint/hooks/pre-commit"

    chmod +x "$TEST/.flint/hooks/pre-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "Pre-hook executed"
    assert "Pre-commit hook should be executed"

    rm -r "$TEST/.flint/hooks"
}


it_runs_post_hook()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Post-hook executed'" >  "$TEST/.flint/hooks/post-commit"

    chmod +x "$TEST/.flint/hooks/post-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "Post-hook executed"
    assert "Post-commit hook should be executed"

    rm -r "$TEST/.flint/hooks"
}


it_runs_pre_and_post_pull_hooks()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Pre-pull executed'" > "$TEST/.flint/hooks/pre-pull"

    echo "echo 'Post-pull executed'" > "$TEST/.flint/hooks/post-pull"

    chmod +x "$TEST/.flint/hooks/pre-pull" "$TEST/.flint/hooks/post-pull"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" pull )
    echo $output | grep -q "Pre-pull executed"
    assert "Pre-pull hook should be executed"
    echo $output | grep -q "Post-pull executed"
    assert "Post-pull hook should be executed"

    rm -r "$TEST/.flint/hooks"
}


it_runs_pre_and_post_push_hooks()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Pre-push executed'" > "$TEST/.flint/hooks/pre-push"

    echo "echo 'Post-push executed'" > "$TEST/.flint/hooks/post-push"

    chmod +x "$TEST/.flint/hooks/pre-push" "$TEST/.flint/hooks/post-push"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" push )
    echo $output | grep -q "Pre-push executed"
    assert "Pre-push hook should be executed"
    echo $output | grep -q "Post-push executed"
    assert "Post-push hook should be executed"

    rm -r "$TEST/.flint/hooks"
}


it_runs_pre_and_post_checkout_hooks()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Pre-checkout executed'" > "$TEST/.flint/hooks/pre-checkout"

    echo "echo 'Post-checkout executed'" > "$TEST/.flint/hooks/post-checkout"

    chmod +x "$TEST/.flint/hooks/pre-checkout" "$TEST/.flint/hooks/post-checkout"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" checkout )
    echo $output | grep -q "Pre-checkout executed"
    assert "Pre-checkout hook should be executed"
    echo $output | grep -q "Post-checkout executed"
    assert "Post-checkout hook should be executed"

    rm -r "$TEST/.flint/hooks"
}


it_skips_missing_pre_hook()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Post-commit executed'" > "$TEST/.flint/hooks/post-commit"

    chmod +x "$TEST/.flint/hooks/post-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -qv "Pre"
    assert "Should not run pre-hook when it does not exist"
    echo $output | grep -q "Post-commit executed"
    assert "Post-commit hook should still run"

    rm -r "$TEST/.flint/hooks"
}


it_skips_missing_post_hook()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Pre-commit executed'" > "$TEST/.flint/hooks/pre-commit"

    chmod +x "$TEST/.flint/hooks/pre-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "Pre-commit executed"
    assert "Pre-commit hook should run"
    echo $output | grep -qv "Post"
    assert "Should not run post-hook when it does not exist"

    rm -r "$TEST/.flint/hooks"
}


it_uses_relative_hooks_path()
{
    mkdir -p "$TEST/.flint/hooks"

    echo "echo 'Relative hook executed'" > "$TEST/.flint/hooks/pre-commit"

    chmod +x "$TEST/.flint/hooks/pre-commit"

    output=$( config="$TEST/flint.config.json" hooks=".flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "Relative hook executed"
    assert "Should resolve relative hooks path"

    rm -r "$TEST/.flint/hooks"
}


it_exports_and_unsets_flint_config()
{
    mkdir -p "$TEST/.flint/hooks"

    echo 'echo "CONFIG=$FLINT_CONFIG"' > "$TEST/.flint/hooks/pre-commit"

    chmod +x "$TEST/.flint/hooks/pre-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "CONFIG=$TEST/flint.config.json"
    assert "FLINT_CONFIG should be set during hook execution"
    [[ -z "$FLINT_CONFIG" ]]
    assert "FLINT_CONFIG should be unset after wrapper completes"

    rm -r "$TEST/.flint/hooks"
}


it_exports_and_unsets_flint_hooks()
{
    mkdir -p "$TEST/.flint/hooks"

    echo 'echo "HOOKS=$FLINT_HOOKS"' > "$TEST/.flint/hooks/pre-commit"

    chmod +x "$TEST/.flint/hooks/pre-commit"

    output=$( config="$TEST/flint.config.json" hooks="$TEST/.flint/hooks" source "$TEST/.core/wrapper.sh" commit )
    echo $output | grep -q "HOOKS=$TEST/.flint/hooks"
    assert "FLINT_HOOKS should be set during hook execution"
    [[ -z "$FLINT_HOOKS" ]]
    assert "FLINT_HOOKS should be unset after wrapper completes"

    rm -r "$TEST/.flint/hooks"
}
