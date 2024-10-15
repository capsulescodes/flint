#!/bin/bash

config="flint.config.json"
hooks=".flint/hooks"



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



if is_flint_hook "pre-$1" && [ ! -f "$PWD/$config" ]

then
    printf "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory ( $PWD ). Running default git.\033[0m\n\n"
fi




if is_flint_hook "pre-$1" && [ -f "$PWD/$config" ] && [[ -f "$PWD/$hooks/pre-$1" ]]

then
    export FLINT_CONFIG="$PWD/$config"

    "$PWD/$hooks/pre-$1"

    unset FLINT_CONFIG
fi




command git "$@"

return="$?"




if is_flint_hook "post-$1" && [ -f "$PWD/$config" ] && [[ -f "$PWD/$hooks/post-$1" ]]

then
    export FLINT_CONFIG="$PWD/$config"

    "$PWD/$hooks/post-$1"

    unset FLINT_CONFIG
fi


return "$return"
