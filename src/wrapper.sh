#!/bin/bash


if [ ! -f "$config" ]

then
    printf "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory. Running default git.\033[0m\n\n"
else
    source "$( cd "$( dirname "${BASH_SOURCE:-$0}" )" && pwd )/functions.sh"
fi




if [ -f "$config" ] && [[ -f "$PWD/$hooks/pre-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    export -f format_for_remote

    "$PWD/$hooks/pre-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS

    unset -f format_for_remote
fi




command git "$@"

return="$?"




if [ -f "$config" ] && [[ -f "$PWD/$hooks/post-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    export -f format_for_local

    "$PWD/$hooks/post-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS

    unset -f format_for_local
fi




return "$return"
