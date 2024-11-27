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

    rm -rf $LOCAL
}




it_runs_flint_h()
{
    output=$( flint -h )
    echo $output | grep -q "Usage: flint"
    assert "Should output help section"
}


it_runs_flint_help()
{
    output=$( flint --help )
    echo $output | grep -q "Usage: flint"
    assert "Should output help section"
}


it_lists_options()
{
    output=$( flint --help )
    echo $output | grep -q "
    -i, --init         Initiates the Flint configuration and mandatory files.

    -r, --run          Runs the Flint process. If no parameters are passed,
                       Flint will default to 'run' mode and execute the process.

    -h, --help         Displays this help message with information on usage
                       and available options."
    assert "Should output options"
}


it_lists_examples()
{
    output=$( flint --help )
    echo $output | grep -q "
    flint --init       # Initializes Flint configuration
    flint              # Runs Flint ( default action )
    flint -h           # Shows help information."
    assert "Should output examples"
}
