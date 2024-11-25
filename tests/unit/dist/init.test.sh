beforeEach()
{
    TEST=$( mktemp -d )


    mkdir -p "$TEST/.core"

    cp -r "$PWD/dist" "$TEST/.core/dist"

    cp -r "$PWD/src" "$TEST/.core/src"

    cp -r "$PWD/hooks" "$TEST/.core/hooks"

    cp "$PWD/template.config.json" "$TEST/.core/template.config.json"

    sed -i "" "s|\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/..|$TEST/.core|" "$TEST/.core/dist/init.sh"


    cd $TEST > /dev/null || exit 1

    INIT_CWD=$TEST
}

afterEach()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}




it_creates_flint_directory()
{
    ( sh "$TEST/.core/dist/init.sh" > /dev/null )
    [ -d "$TEST/.flint" ]
    assert "Should create '.flint' directory"
}


it_copies_hooks_when_requested()
{
    ( sh "$TEST/.core/dist/init.sh" --with-hooks > /dev/null )
    [ -d "$TEST/.flint/hooks" ]
    assert "Should copy hooks directory when --with-hooks is specified"

    rm -rf "$TEST/.flint"

    ( sh "$TEST/.core/dist/init.sh" > /dev/null )
    [ ! -d "$TEST/.flint/hooks" ]
    assert "Should not copy hooks directory without --with-hooks flag"
}


it_creates_git_wrapper()
{
    ( sh "$TEST/.core/dist/init.sh" > /dev/null )
    [ -f "$TEST/.flint/git.sh" ]
    assert "Should create git.sh wrapper"

    [ -x "$TEST/.flint/git.sh" ]
    assert "git.sh should be executable"
}


it_handles_missing_source_files()
{
    mv "$TEST/.core/hooks" "$TEST/.core/hooks-bak"
    mv "$TEST/.core/src/wrapper.sh" "$TEST/.core/src/wrapper.sh.bak"

    output=$( sh "$TEST/.core/dist/init.sh" )
    echo $output | grep -q "Required files not found"
    assert "Should error when required files are missing"

    mv "$TEST/.core/hooks-bak" "$TEST/.core/hooks"
    mv "$TEST/.core/src/wrapper.sh.bak" "$TEST/.core/src/wrapper.sh"
}


it_creates_valid_wrapper_script()
{
    ( sh "$TEST/.core/dist/init.sh" > /dev/null )
    grep -q "config=\"flint.config.json\"" "$TEST/.flint/git.sh"
    assert "Generated git.sh should contain config variable"
    grep -q "source" "$TEST/.flint/git.sh"
    assert "Generated git.sh should source wrapper script"
}


it_creates_flint_config_json()
{
    ( sh "$TEST/.core/dist/init.sh" > /dev/null )
    [[ -f "$TEST/flint.config.json" ]]
    assert "Should create flint.config.json at project root"
}


it_adds_git_wrapper_to_shell_config()
{
    touch "$TEST/.bashrc"

    command="git() { \[\[ -f \"\$PWD/.flint/git.sh\" \]\] && source \"\$PWD/.flint/git.sh\" || command git \$@ }"

    ( SHELL="/bin/bash" HOME=$TEST sh "$TEST/.core/dist/init.sh" > /dev/null )
    echo "$( cat "$TEST/.bashrc" )" | grep -q "$command"
    assert "Should add git wrapper function to bashrc file"

    ( SHELL="/bin/bash" HOME=$TEST sh "$TEST/.core/dist/init.sh" > /dev/null )
    [[ $( grep -c "git()" "$TEST/.bashrc" ) -eq 1 ]]
    assert "Should not add git wrapper function multiple times"

    rm "$TEST/.bashrc"
}


it_handles_nonexistent_profile()
{
    ( SHELL="/bin/bash" HOME="$TEST/home" sh "$TEST/.core/dist/init.sh" > /dev/null )
    [ ! -f "$TEST/home/.bashrc" ]
    assert "Should not fail if profile does not exist"
}
