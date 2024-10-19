#!/bin/bash

function is_flint_hook
{
    flint_hooks=( "post-pull" "pre-commit" "post-commit" "pre-push" "post-push" )

    for hook in "${flint_hooks[@]}"

    do
        if [[ "$hook" == "$1" ]]

        then
            return 0
        fi
    done

    return 1
}




if is_flint_hook "pre-$1" && [ ! -f "$config" ]

then
    printf "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory. Running default git.\033[0m\n\n"
else
    source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/functions.sh"
fi


is_flint_hook "pre-$1" && echo "YES" || echo "NO"
[ -f "$config" ] && echo "YES" || echo "NO"
[[ -f "$PWD/$hooks/pre-$1" ]] && echo "YES" || echo "NO"
echo "$PWD/$hooks/pre-$1"

if is_flint_hook "pre-$1" && [ -f "$config" ] && [[ -f "$PWD/$hooks/pre-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    "$hooks/pre-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




command git "$@"

return="$?"




if is_flint_hook "post-$1" && [ -f "$config" ] && [[ -f "$PWD/$hooks/post-$1" ]]

then
    export FLINT_CONFIG="$config"

    export FLINT_HOOKS="$hooks"

    "$hooks/post-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




return "$return"
