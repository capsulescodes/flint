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




it_lists_options()
{
    output=$( flint --help )
    echo $output | grep -q "
    -i, --init         Initializes the configuration.
        --with-hooks   Initializes the configuration with modifiable hooks included.
        --no-wrap      Initializes the configuration without the Git wrapper function.

    -r, --run          Execute the process.
                       Defaults to 'local' mode if no parameters are specified.

    -h, --help         Display this help guide with information on usage
                       and available options."
    assert "Should output options"
}


it_lists_examples()
{
    output=$( flint --help )
    echo $output | grep -q "
    flint --init       Initializes the configuration.
    flint              Run Flint wrapped Git functionality.
    flint -h           Shows help information."
    assert "Should output examples"
}
