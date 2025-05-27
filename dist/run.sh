#!/bin/bash




destination="${INIT_CWD:+$INIT_CWD/}.flint"

if [[ ! -d $destination || ! -f "$destination/git.sh" ]]

then
    printf "\n\033[1;33mflint - Flint must be configured first. Run 'flint init' to proceed.\033[0m\n\n"

    exit 1
fi

config="$( grep '^config=' "$destination/git.sh" | cut -d '=' -f 2 | tr -d '"')"

if [[ ! -f $config ]]

then
    printf "\n\033[1;33mflint - The '$config' file does not exist in the root directory.\033[0m\n\n"

    exit 1
fi


source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/functions.sh"




unstaged=$( git diff --name-only )

staged=$( git diff --staged --name-only )


patched=()

while IFS= read -r file

do
    if [[ -n $file ]] && echo "$unstaged" | grep -Fqx "$file"

    then
        patched+=( "$file" )
    fi

done <<< "$staged"


if [[ -n ${patched[0]} ]]

then
    patch=$( git diff "${patched[@]}" | git hash-object -w --stdin )

    git stash push -- "${patched[@]}"
fi


if [[ -n $staged ]]

then
    git restore --staged $staged
fi

manual=$( git rev-list HEAD --invert-grep --grep='FLINT-TEMPORARY-COMMIT' --max-count=1 )

if [[ -n $manual ]]

then
    git reset --soft $manual --quiet
fi


eval_for_command "$( [[ -n $2 ]] && echo "$2" || echo "local" )" $config

modified=$( git diff --diff-filter=d --name-only )

files=()

while IFS= read -r file

do
    if [[ -n $file ]] && ! echo "$unstaged" | grep -Fqx "$file" && ! echo "$staged" | grep -Fqx "$file"

    then
        files+=( "$file" )
    fi
done <<< "$modified"


if [[ -n ${files[0]} ]]

then
    git add "${files[@]}"
fi

reset=$( git diff --diff-filter=d --staged --name-only )

if [[ -n $reset ]]

then
    export FLINT_TEMPORARY_COMMIT=1

    git commit -m "FLINT-TEMPORARY-COMMIT" --quiet

    unset FLINT_TEMPORARY_COMMIT
fi


if [[ -n $staged ]]

then
    git add "$staged"
fi


if [[ -n $patch ]]

then
    git cat-file -p "$patch" | git apply

    eval_for_command "$( [[ -n $2 ]] && echo "$2" || echo "local" )" $config "$patched"
fi
