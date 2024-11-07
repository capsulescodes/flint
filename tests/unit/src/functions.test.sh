beforeAll()
{
    TEST=$( mktemp -d )

    mkdir "$TEST/.flint"

    cp "$PWD/src/functions.sh" "$TEST/.flint/functions.sh"

    cp "$PWD/tests/fixtures/"* "$TEST"

    cd "$TEST" > /dev/null || exit 1

    source .flint/functions.sh > /dev/null
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}




it_handles_missing_binary()
{
    output=$( format_for_local "config.002.json" "foo.js" 2>&1 )
    echo "$output" | grep -q "Warning : No binary or local command associated with a linter. Skipping."
    assert "Should warn when binary is missing from the configuration"
}


it_handles_missing_local_command()
{
    output=$( format_for_local "config.002.json" "foo.js" 2>&1 )
    echo "$output" | grep -q "Warning : No binary or local command associated with a linter. Skipping."
    assert "Should warn when local command is missing"
}


it_handles_missing_remote_command()
{
    output=$( format_for_remote "config.002.json" "foo.js" 2>&1 )
    echo "$output" | grep -q "Warning : No binary or remote command associated with a linter. Skipping."
    assert "Should warn when remote command is missing"
}


it_checks_if_binary_file_exists()
{
    output=$( format_for_local "config.006.json" "foo.js" )
    echo "$output" | grep -q "Warning : Binary \"foo/bar/echo\" not found. Install it and run 'flint run'. Skipping."
    assert "Should warn when binary file is missing"

    mkdir -p "$TEST/foo/bar"

    cp "$TEST/echo" "$TEST/foo/bar/echo"

    output=$( format_for_local "config.006.json" "foo.js" )
    echo "$output" | grep -q "local_js_lint foo.js"
    assert "Should run the lint command when binary exists"


    rm -rf foo
}


it_handles_empty_file_list()
{
    output=$( format_for_local "config.001.json" )
    echo "$output" | grep -q "local_js_lint ."
    assert "Should run the lint command for every file [ local ]"

    output=$( format_for_remote "config.001.json" )
    echo "$output" | grep -q "remote_js_lint ."
    assert "Should run the lint command for every file [ remote ]"
}


it_formats_for_local()
{
    output=$( format_for_local "config.001.json" "foo.js bar.php baz.py" )
    echo "$output" | grep -q "local_js_lint foo.js"
    assert "Should run local lint command for js files"
    echo "$output" | grep -q "local_php_lint bar.php"
    assert "Should run local lint command for php files"
    echo "$output" | grep -qv "baz.py"
    assert "Should not lint python files"
}


it_formats_for_remote()
{
    output=$( format_for_remote "config.001.json" "foo.js bar.php baz.py" )
    echo "$output" | grep -q "remote_js_lint foo.js"
    assert "Should run remote lint command for js files"
    echo "$output" | grep -q "remote_php_lint bar.php"
    assert "Should run remote lint command for php files"
    echo "$output" | grep -qv "baz.py"
    assert "Should not lint python files"
}
