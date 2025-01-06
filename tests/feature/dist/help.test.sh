beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/bin/" "$LOCAL/.core/bin"

    cp -r "$PWD/dist/" "$LOCAL/.core/dist"

    sed -i "" "s|path=\"\$( cd -P \"\$( dirname \$target )\" && pwd )/../dist|path=\"$LOCAL/.core/dist|" "$LOCAL/.core/bin/flint"


    cd $LOCAL > /dev/null || exit 1

    mock $LOCAL
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_lists_options()
{
    output=$( flint --help )
    echo $output | grep -q "
    -i, --init         Sets up Flint in the current project.
        --wrap         Integrates a Git wrapper function into local shell configuration file.
        --hooks        Includes modifiable hooks for custom workflows.
        --no-config    Skips default configuration template integration.

    -r, --run          Executes the process.
                       Defaults to 'local' mode if no parameters are specified.

    -h, --help         Displays this help guide with information on usage
                       and available options."
    assert "Should output options"
}


it_lists_examples()
{
    output=$( flint --help )
    echo $output | grep -q "
    flint              Run Flint wrapped Git functionality.
    flint --init       Sets up Flint in the current project with default settings.
    flint -i --wrap    Sets up Flint and integrates the Git wrapper function into the shell."
    assert "Should output examples"
}
