#!/bin/bash


if [[ -f "$PWD/$hooks/pre-$1" ]] && [ ! -f "$config" ]

then
    printf "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory. Running default git.\033[0m\n\n"
else
    source "$( cd "$( dirname "${BASH_SOURCE}" )" && pwd )/functions.sh"
fi




if [[ -f "$PWD/$hooks/pre-$1" ]] && [ -f "$config" ] && [[ -f "$PWD/$hooks/pre-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    "$PWD/$hooks/pre-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




command git "$@"

return="$?"




if [[ -f "$PWD/$hooks/post-$1" ]] && [ -f "$config" ] && [[ -f "$PWD/$hooks/post-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    "$PWD/$hooks/post-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




return "$return"
