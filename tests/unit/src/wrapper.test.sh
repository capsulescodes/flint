beforeAll()
{
    TEST=$( mktemp -d )


    mkdir "$TEST/.core"

    cp "$PWD/src/wrapper.sh" "$TEST/.core/wrapper.sh"

    cp "$PWD/stubs/config.json" "$TEST/flint.config.json"

    sed -i '' $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$TEST/.core/wrapper.sh"

    sed -i "" "s|command git \"\$@\"|echo \"git\"|" "$TEST/.core/wrapper.sh"


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
