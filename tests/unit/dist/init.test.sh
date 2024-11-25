beforeEach()
{
    TEST=$( mktemp -d )

    path=$PWD

    cd $TEST > /dev/null || exit 1
}

afterEach()
{
    cd - > /dev/null || exit 1

    rm -rf $TEST
}




it_prevents_double_initialization()
{
    INIT_CWD=$TEST sh "$path/dist/init.sh" init > /dev/null
    [ "$?" -eq 0 ]
    assert "Should exit cleanly when INIT_CWD equals PWD"
}


it_creates_flint_directory()
{
    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init > /dev/null
    [ -d "$TEST/.flint" ]
    assert "Should create .flint directory"
}


it_copies_hooks_when_requested()
{
    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init --with-hooks > /dev/null
    [ -d "$TEST/.flint/hooks" ]
    assert "Should copy hooks directory when --with-hooks is specified"

    rm -rf "$TEST/.flint"

    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init > /dev/null
    [ ! -d "$TEST/.flint/hooks" ]
    assert "Should not copy hooks directory without --with-hooks flag"
}


it_creates_git_wrapper()
{
    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init > /dev/null
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

    output=$( INIT_CWD=$TEST PWD=$path sh "$TEST/dist/init.sh" init 2>&1 ) > /dev/null
    echo $output | grep -q "Required files not found"
    assert "Should error when required files are missing"

    rm -rf "$TEST/dist"
    rm -rf "$TEST/src"
}


it_creates_valid_wrapper_script()
{
    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init > /dev/null

    grep -q "config=\"flint.config.json\"" "$TEST/.flint/git.sh"
    assert "Generated git.sh should contain config variable"

    grep -q "source" "$TEST/.flint/git.sh"
    assert "Generated git.sh should source wrapper script"
}


it_creates_flint_config_json()
{
    INIT_CWD=$TEST PWD=$path sh "$path/dist/init.sh" init > /dev/null
    [ -f "$TEST/flint.config.json" ]
    assert "Should create flint.config.json at project root"
}


it_adds_git_wrapper_to_shell_config()
{
    mkdir -p "$TEST/home"

    touch "$TEST/home/.bashrc"

    command="git() { [[ -f \"\$PWD/.flint/git.sh\" ]] && source \"\$PWD/.flint/git.sh\" || command git \$@ }"

    INIT_CWD=$TEST PWD=$path SHELL="/bin/bash" HOME="$TEST/home" sh "$path/dist/init.sh" init > /dev/null
    grep -Fq "$command" "$TEST/home/.bashrc"
    assert "Should add git wrapper function to bashrc file"

    INIT_CWD=$TEST PWD=$path SHELL="/bin/bash" HOME="$TEST/home" sh "$path/dist/init.sh" init > /dev/null
    [ "$( grep -Fc "$command" "$TEST/home/.bashrc" )" -eq 1 ]
    assert "Should not add git wrapper function multiple times"
}


it_handles_unknown_shell()
{
    mkdir -p "$TEST/home"

    touch "$TEST/home/.unknownrc"

    command="git() { [[ -f \"\$PWD/.flint/git.sh\" ]] && source \"\$PWD/.flint/git.sh\" || command git \"\$@\" }"

    INIT_CWD=$TEST PWD=$path SHELL="/bin/unknown" HOME="$TEST/home" sh "$path/dist/init.sh" init > /dev/null
    [ "$( grep -Fc "$command"  "$TEST/home/.unknownrc" )" -eq 0 ]
    assert "Should not attempt to modify shell config for unknown shells"
}


it_handles_nonexistent_profile()
{
    INIT_CWD=$TEST PWD=$path SHELL="/bin/bash" HOME="$TEST/home" sh "$path/dist/init.sh" init > /dev/null
    [ ! -f "$TEST/home/.bashrc" ]
    assert "Should not fail if profile does not exist"
}
