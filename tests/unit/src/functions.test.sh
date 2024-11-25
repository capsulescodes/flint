beforeAll()
{
    TEST=$( mktemp -d )


    mkdir "$TEST/.core"

    cp -r "$PWD/src/functions.sh" "$TEST/.core/functions.sh"

    cp "$PWD/tests/fixtures/echo" "$TEST/.core/echo"

    cp "$PWD/tests/fixtures/config"* $TEST

    cd $TEST > /dev/null || exit 1

    source "$TEST/.core/functions.sh"
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}




it_handles_missing_binary()
{
    output=$( eval_for_command "local" "config.002.json" "file.foo" 2>&1 )
    echo $output | grep -q "No binary or 'local' command associated with a linter. Skipping."
    assert "Should warn when binary is missing from the configuration"
}


it_handles_missing_local_command()
{
    output=$( eval_for_command "local" "config.002.json" "file.foo" 2>&1 )
    echo $output | grep -q "No binary or 'local' command associated with a linter. Skipping."
    assert "Should warn when local command is missing"
}


it_handles_missing_remote_command()
{
    output=$( eval_for_command "remote" "config.002.json" "file.foo" 2>&1 )
    echo $output | grep -q "No binary or 'remote' command associated with a linter. Skipping."
    assert "Should warn when remote command is missing"
}


it_checks_if_binary_file_exists()
{
    output=$( eval_for_command "local" "config.005.json" "file.foo" )
    echo $output | grep -q "Binary 'foo/bar/echo' not found. Install it and run 'flint run'. Skipping."
    assert "Should warn when binary file is missing"


    mkdir -p "$TEST/foo/bar"

    cp "$TEST/.core/echo" "$TEST/foo/bar/echo"

    output=$( eval_for_command "local" "config.005.json" "file.foo" )
    echo $output | grep -q "local_foo file.foo"
    assert "Should run the lint command when binary exists"

    rm -rf "$TEST/foo"
}


it_handles_empty_file_list()
{
    output=$( eval_for_command "local" "config.001.json" )
    echo $output | grep -q "local_foo ."
    assert "Should run the lint command for every file [ local ]"

    output=$( eval_for_command "remote" "config.001.json" )
    echo $output | grep -q "remote_foo ."
    assert "Should run the lint command for every file [ remote ]"
}


it_evals_for_local()
{
    output=$( eval_for_command "local" "config.001.json" "file.foo file.bar file.baz" )
    echo $output | grep -q "local_foo file.foo"
    assert "Should run local lint command for foo files"
    echo $output | grep -q "local_bar file.bar"
    assert "Should run local lint command for bar files"
    echo $output | grep -qv "file.baz"
    assert "Should not lint baz files"
}


it_evals_for_remote()
{
    output=$( eval_for_command "remote" "config.001.json" "file.foo file.bar file.baz" )
    echo $output | grep -q "remote_foo file.foo"
    assert "Should run remote lint command for foo files"
    echo $output | grep -q "remote_bar file.bar"
    assert "Should run remote lint command for bar files"
    echo $output | grep -qv "file.baz"
    assert "Should not lint bazfiles"
}
