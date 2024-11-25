#!/bin/bash




destination="${INIT_CWD:+$INIT_CWD/}.flint"

if [[ ! -d $destination || ! -f "$destination/git.sh" ]]

then
    printf "\n\033[1;33m[ Flint ] Flint must be configured first. Run 'flint init' to proceed.\033[0m\n\n"

    exit 0
fi

config="$( grep '^config=' "$destination/git.sh" | cut -d '=' -f 2 | tr -d '"')"

if [[ ! -f $config ]]

then
    printf "\n\033[1;33m[ Flint ] The '$config' file does not exist in the root directory.\033[0m\n\n"

    exit 0
fi


source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/functions.sh"




unstaged=$( git diff --name-only )

staged=$( git diff --diff-filter=d --staged --name-only )

manual=$( git rev-list HEAD --invert-grep --grep='FLINT-TEMPORARY-COMMIT' --max-count=1 )

if [[ -n $manual ]]

then
    git reset --soft $manual --quiet
fi

reset=$( git diff --diff-filter=d --staged --name-only )

command=$( [[ -n $2 ]] && echo "$2" || echo "local" )

eval_for_command $command $config

modified=$( git diff --name-only )

files=()


while IFS= read -r file

do
    if [ -n "$file" ] && echo "$modified" | grep -Fqx "$file" && ! echo "$unstaged" | grep -Fqx "$file" && ! echo "$staged" | grep -Fqx "$file"

    then
        files+=( $file )
    fi
done <<< "$modified"


[[ ${#files[@]} -gt 0 ]] && git add "${files[@]}"

if [[ ${#files[@]} -gt 0 || ! "$reset" == "$staged" ]]

then
    [[ -n $staged ]] && git restore --staged "$staged"

    export FLINT_TEMPORARY_COMMIT=1

    git commit -m "FLINT-TEMPORARY-COMMIT" --quiet

    unset FLINT_TEMPORARY_COMMIT
fi

[[ -n $staged ]] && git add "$staged"
