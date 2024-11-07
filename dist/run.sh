#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/functions.sh"


[[ "$INIT_CWD" == "$PWD" ]] && exit 0




manual=$( git rev-list HEAD --invert-grep --grep='FLINT-FIX-TEMP-COMMIT' --max-count=1 )

if [ -n "$manual" ]

then
    git reset --soft "$manual" --quiet
fi

format_for_local "$FLINT_CONFIG"

modified=$( git diff --name-only --diff-filter=M )

if [ ${#modified[@]} -gt 0 ]

then
    git add "${modified[@]}"

    export FLINT_FIX_TEMP_COMMIT=1

    git commit -m "FLINT-FIX-TEMP-COMMIT" --quiet

    unset FLINT_FIX_TEMP_COMMIT
fi
