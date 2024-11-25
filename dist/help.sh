#!/bin/bash

cat << EOF

Usage: flint [OPTION]

Options:
    -i, --init         Initiates the Flint configuration and mandatory files.

    -r, --run          Runs the Flint process. If no parameters are passed,
                       Flint will default to 'run' mode and execute the process.

    -h, --help         Displays this help message with information on usage
                       and available options.

Examples:
    flint --init       # Initializes Flint configuration
    flint              # Runs Flint ( default action )
    flint -h           # Shows help information.

EOF
