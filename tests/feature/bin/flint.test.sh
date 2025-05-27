beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/bin/" "$LOCAL/.core/bin"

    cp -r "$PWD/dist/" "$LOCAL/.core/dist"

    cp -r "$PWD/src/" "$LOCAL/.core/src"

    INIT_CWD=$LOCAL bash "$PWD/dist/init.sh" --hooks > /dev/null

    sed -i.bak -e "s|${PWD}|${LOCAL}/.core|" "$LOCAL/.flint/git.sh"

    sed -i.bak -e "s|path=\"\$( cd -P \"\$( dirname \$target )\" && pwd )/../dist|path=\"$LOCAL/.core/dist|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|bash \"\$path/run|source \"\$path/run|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|command git \"\$@\"|echo \"git command run from binary \"|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|source \"\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/../src/functions.sh\"||" "$LOCAL/.core/dist/run.sh"

    sed -i.bak -e $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|command git \"\$@\"|echo \"git command run from wrapper \"|" "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|eval_for_command|mock_for_command|" "$LOCAL/.core/src/functions.sh"

    cp "$PWD/tests/fixtures/config.007.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.core/replace"


    cd $LOCAL > /dev/null || exit 1

    source "$LOCAL/.core/src/functions.sh"

    mock $LOCAL

    INIT_CWD=$LOCAL
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_runs_flint_help_command()
{
    output=$( flint help )
    echo $output | grep -q "Usage: flint"
    assert "Should output help section"
}


it_runs_flint_init_command()
{
    output=$( flint init )
    [[ -d "$LOCAL/.flint" && -f "$LOCAL/flint.config.json" ]]
    assert "Should create flint files and directories"
}


it_runs_flint_init_foo_command()
{
    output=$( flint init --foo )
    echo $output | grep -q "'--foo' is not a valid option. Type 'flint help' to display help section."
    assert "Should create flint files and directories"
}


it_runs_flint_run_command()
{
    echo "remote" > file.001.foo

    output=$( flint run )
    [[ "$( cat "$LOCAL/file.001.foo" )" == "local" ]]
    assert "flint - Should modify file locally"

    rm file.001.foo
}


it_runs_flint_command()
{
    output=$( flint )
    echo $output | grep -q "Running wrapped git."
    assert "Should output message before wrapper"
    echo $output | grep -q "git command run from wrapper"
    assert "Should output git error from wrapper"

    mv "$LOCAL/.flint" "$LOCAL/.flint-bak"

    output=$( flint )
    echo $output | grep -q "'git.sh' file not found in '.flint' directory. Running default git."
    assert "Should output message before binary"
    echo $output | grep -q "git command run from binary"
    assert "Should output git error from binary"

    mv "$LOCAL/.flint-bak" "$LOCAL/.flint"
}
