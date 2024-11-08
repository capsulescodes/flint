#!/bin/bash

[[ "$INIT_CWD" == "$PWD" ]] && exit 0




destination="${INIT_CWD:+$INIT_CWD/}.flint"

if [[ ! -d "$destination" ]] || [[ ! -f "$destination/git.sh" ]]

then
    printf "\n\033[1;33m[ Flint ] Flint must be configured first. Run 'flint init' to proceed.\033[0m\n"

    exit 0
fi

config="$( grep '^config=' "$destination/git.sh" | cut -d '=' -f 2 | tr -d '"')"

if [ ! -f "$config" ]

then
    printf "\n\033[1;33mWarning : The \"$config\" file does not exist in the root directory.\033[0m\n\n"

    exit 0
fi


source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/functions.sh"




manual=$( git rev-list HEAD --invert-grep --grep='FLINT-FIX-TEMP-COMMIT' --max-count=1 )

if [ -n "$manual" ]

then
    git reset --soft "$manual" --quiet
fi




staged=$( git diff --staged --name-only )

unstaged=$( git diff --name-only )

format_for_local "$config"

modified=$( git diff --name-only )

before=()

after=()

while IFS= read -r file

do
    if ( ! echo "$staged" | grep -Fqx "$file" ) && ( ! echo "$unstaged" | grep -Fqx "$file" )

    then
        before+=( "$file" )
    fi

    if echo "$staged" | grep -Fqx "$file"

    then
        after+=( "$file" )

        continue
    fi
done <<< "$modified"




if [ ${#before[@]} -gt 0 ]

then
    git add "${before[@]}"

    export FLINT_FIX_TEMP_COMMIT=1

    git commit -m "FLINT-FIX-TEMP-COMMIT" --quiet

    unset FLINT_FIX_TEMP_COMMIT
fi


if [ ${#after[@]} -gt 0 ]

then
    git add "${after[@]}"
fi
