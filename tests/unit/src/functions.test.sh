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

    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}




it_handles_missing_binary()
{
    output=$( eval_for_command "local" "config.002.json" "file.foo" 2>&1 )
    echo $output | grep -q "No binary associated with linter. Skipping."
    assert "Should warn when binary is missing from the configuration"
}


it_handles_missing_command()
{
    output=$( eval_for_command "foo" "config.003.json" "file.foo" 2>&1 )
    echo $output | grep -q "No 'foo' command associated with linter. Skipping."
    assert "Should warn when local command is missing"
}


it_silently_handles_incorrect_command()
{
    output=$( eval_for_command "foo/bar.baz" "config.005.json" 2>&1 )
    ! echo $output | grep -Fq "sed: 1: \"s/.*\"foo/bar.baz\"[[:spa ...\": bad flag in substitute command: '\'"
    assert "Should not  when local command is missing"
    echo $output | grep -q "No 'foo/bar.baz' command associated with linter. Skipping."
    assert "Should warn when local command is missing"
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

    rm -r "$TEST/foo"
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


it_evaluates_for_local()
{
    output=$( eval_for_command "local" "config.001.json" "file.foo file.bar file.baz" )
    echo $output | grep -q "local_foo file.foo"
    assert "Should run local lint command for foo files"
    echo $output | grep -q "local_bar file.bar"
    assert "Should run local lint command for bar files"
    echo $output | grep -qv "file.baz"
    assert "Should not lint baz files"
}


it_evaluates_for_remote()
{
    output=$( eval_for_command "remote" "config.001.json" "file.foo file.bar file.baz" )
    echo $output | grep -q "remote_foo file.foo"
    assert "Should run remote lint command for foo files"
    echo $output | grep -q "remote_bar file.bar"
    assert "Should run remote lint command for bar files"
    echo $output | grep -qv "file.baz"
    assert "Should not lint bazfiles"
}


it_handles_multiple_extensions()
{
    output=$( eval_for_command "local" "config.008.json" "file.js file.jsx file.ts file.txt" )
    echo $output | grep -q "local_foo file.js"
    assert "Should match .js files"
    echo $output | grep -q "file.jsx"
    assert "Should match .jsx files"
    echo $output | grep -q "file.ts"
    assert "Should match .ts files"
    echo $output | grep -qv "file.txt"
    assert "Should not match .txt files"
}


it_handles_file_with_multiple_dots()
{
    output=$( eval_for_command "local" "config.003.json" "file.test.foo" )
    echo $output | grep -q "local_foo file.test.foo"
    assert "Should match files with multiple dots"
}


it_does_not_match_extension_substring()
{
    output=$( eval_for_command "local" "config.003.json" "file.foobar" )
    echo $output | grep -qv "file.foobar"
    assert "Should not match files whose extension is a superset"
}


it_filters_unmatched_extensions()
{
    output=$( eval_for_command "local" "config.003.json" "file.txt file.md" )
    echo $output | grep -qv "file.txt"
    assert "Should not lint unmatched extensions"
    echo $output | grep -qv "file.md"
    assert "Should not lint unmatched extensions"
}


it_continues_when_one_linter_binary_is_missing()
{
    output=$( eval_for_command "local" "config.009.json" "file.foo file.bar" )
    echo $output | grep -q "local_foo file.foo"
    assert "Should run the first linter that has a valid binary"
    echo $output | grep -q "Binary 'missing/binary' not found"
    assert "Should warn about the missing binary"
}


it_handles_empty_config()
{
    output=$( eval_for_command "local" "config.010.json" "file.foo" 2>&1 )
    echo $output | grep -qv "local_foo"
    assert "Should not run any linter with empty config"
}
