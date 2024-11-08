#!/bin/bash

printf "\033[1;30m"

cat << EOF

Usage: flint [OPTION]

Flint empowers developers to code using their personal style and formatting preferences locally,
while ensuring that the codebase remains consistent with the team's standards.

Options:
  init                 Initiates the Flint configuration and mandatory files.

  run                  Runs the Flint process. If no parameters are passed,
                       Flint will default to "run" mode and execute the process.

  -h, --help           Displays this help message with information on usage
                       and available options.

Examples:
  flint init           # Initializes Flint configuration.
  flint                # Runs Flint ( default action ).
  flint -h             # Shows help information.

EOF

printf "\033[0m"
