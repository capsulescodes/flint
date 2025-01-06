#!/bin/bash

cat << EOF

Usage: flint [OPTION]

Options:
    -i, --init         Sets up Flint in the current project.
        --wrap         Integrates a Git wrapper function into local shell configuration file.
        --hooks        Includes modifiable hooks for custom workflows.
        --no-config    Skips default configuration template integration.

    -r, --run          Executes the process.
                       Defaults to 'local' mode if no parameters are specified.

    -h, --help         Displays this help guide with information on usage
                       and available options.

Examples:
    flint              Run Flint wrapped Git functionality.
    flint --init       Sets up Flint in the current project with default settings.
    flint -i --wrap    Sets up Flint and integrates the Git wrapper function into the shell.

EOF
