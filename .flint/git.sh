#!/bin/bash

cmd="$1"

hooks_path=hooks

flint_hooks=( "post-pull" "pre-commit" "post-commit" "pre-push" "post-push" )

is_flint_hook()
{
    for hook in "${new_hooks[@]}"

    do
        if [[ "$hook" == "$1" ]]

        then
            return 0
        fi
    done

    return 1
}

if is_flint_hook "pre-$cmd" && [[ -n "$hooks_path" && -f "$hooks_path/pre-$cmd" ]]; then
    "$hooks_path/pre-$cmd"
fi

command git "$@"

return_val="$?"

if is_flint_hook "post-$cmd" && [[ -n "$hooks_path" && -f "$hooks_path/post-$cmd" ]]; then
    "$hooks_path/post-$cmd"
fi


return "$return_val"
