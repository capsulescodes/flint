beforeAll()
{
    TEST=$( mktemp -d )

    path=$PWD

    cd "$TEST" > /dev/null || exit 1
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}




it_prevents_double_initialization()
{
    INIT_CWD="$path" output=$( sh "$path/dist/init.sh" 2>&1 )
    [ "$?" -eq 0 ]
    assert "Should exit cleanly when INIT_CWD equals PWD"
}


it_creates_flint_directory()
{

    INIT_CWD="$TEST" PWD="$path" sh "$path/dist/init.sh"
    [ -d "$TEST/.flint" ]
    assert "Should create .flint directory"
}


it_copies_hooks_when_requested()
{
    INIT_CWD="$TEST" PWD="$path" sh "$path/dist/init.sh" --with-hooks
    [ -d "$TEST/.flint/hooks" ]
    assert "Should copy hooks directory when --with-hooks is specified"

    rm -rf "$TEST/.flint"

    INIT_CWD="$TEST" PWD="$path" sh "$path/dist/init.sh"
    [ ! -d "$TEST/.flint/hooks" ]
    assert "Should not copy hooks directory without --with-hooks flag"
}


it_creates_git_wrapper()
{
    INIT_CWD="$TEST" PWD="$path" sh "$path/dist/init.sh"
    [ -f "$TEST/.flint/git.sh" ]
    assert "Should create git.sh wrapper"

    [ -x "$TEST/.flint/git.sh" ]
    assert "git.sh should be executable"
}


it_handles_missing_source_files()
{
    mkdir "$TEST/dist"
    mkdir "$TEST/src"

    cp "$path/dist/init.sh" "$TEST/dist/init.sh"
    cp "$path/src/helpers.sh" "$TEST/src/helpers.sh"

    output=$( sh "$TEST/dist/init.sh" 2>&1 )
    echo "$output" | grep -q "Error: Required files not found"
    assert "Should error when required files are missing"

    rm -rf "$TEST/dist"
    rm -rf "$TEST/src"
}


it_creates_valid_wrapper_script()
{
    INIT_CWD="$TEST" PWD="$path" sh "$path/dist/init.sh"
#
    grep -q "config=\"flint.config.json\"" "$TEST/.flint/git.sh"
    assert "Generated git.sh should contain config variable"
#
    grep -q "source" "$TEST/.flint/git.sh"
    assert "Generated git.sh should source wrapper script"
}
