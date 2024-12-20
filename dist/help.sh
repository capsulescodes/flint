#!/bin/bash

cat << EOF

Usage: flint [OPTION]

Options:
    -i, --init         Initializes the configuration.
        --with-hooks   Initializes the configuration with modifiable hooks included.
        --no-wrap      Initializes the configuration without the Git wrapper function.
        --no-config    Initializes the configuration without the Git configuration template.

    -r, --run          Execute the process.
                       Defaults to 'local' mode if no parameters are specified.

    -h, --help         Display this help guide with information on usage
                       and available options.

Examples:
    flint --init       Initializes the configuration.
    flint              Run Flint wrapped Git functionality.
    flint -h           Shows help information.

EOF
