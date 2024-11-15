if [ ! -f "$config" ]

then
    echo "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory. Running default git.\033[0m\n\n"
else
    source "$( cd "$( dirname "${BASH_SOURCE:-$0}" )" && pwd )/functions.sh"
fi




path=$( [[ "$hooks" == /* ]] && echo "$hooks" || echo "$PWD/$hooks" )


if [ -f "$config" ] && [[ -f "$path/pre-$1" ]]

then
    export FLINT_CONFIG=$config

    export FLINT_HOOKS=$hooks

    source "$PWD/$hooks/pre-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




command git $@

return=$?




if [ -f "$config" ] && [[ -f "$path/post-$1" ]]

then
    export FLINT_CONFIG=$config

    export FLINT_HOOKS=$hooks

    source "$PWD/$hooks/post-$1"

    unset FLINT_CONFIG

    unset FLINT_HOOKS
fi




return $return
