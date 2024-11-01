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




it_formats_for_local()
{
    output=$( format_for_local "config.001.json" "test.js test.php test.py" )
    echo "$output" | grep -q "local_js_lint test.js"
    assert "Should run local lint command for js files"
    echo "$output" | grep -q "local_php_lint test.php"
    assert "Should run local lint command for php files"
    echo "$output" | grep -qv "test.py"
    assert "Should not lint python files"
}

it_formats_for_remote()
{
    output=$( format_for_remote "config.001.json" "test.js test.php test.py" )
    echo "$output" | grep -q "remote_js_lint test.js"
    assert "Should run remote lint command for js files"
    echo "$output" | grep -q "remote_php_lint test.php"
    assert "Should run remote lint command for php files"
    echo "$output" | grep -qv "test.py"
    assert "Should not lint python files"
}

it_handles_missing_local_command()
{
    output=$( format_for_local "config.002.json" "test.js" 2>&1 )
    echo "$output" | grep -q "Warning : No local command associated with a linter. Skipping."
    assert "Should warn when local command is missing"
}

it_handles_missing_remote_command()
{
    output=$( format_for_remote "config.002.json" "test.js" 2>&1 )
    echo "$output" | grep -q "Warning : No remote command associated with a linter. Skipping."
    assert "Should warn when remote command is missing"
}

it_handles_empty_file_list()
{
    output=$( format_for_local "config.001.json" "" )
    [ -z "$output" ]
    assert "Should not produce output for empty file list [ local ]"

    output=$( format_for_remote "config.001.json" "" )
    [ -z "$output" ]
    assert "Should not produce output for empty file list [ remote ]"
}
