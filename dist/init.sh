#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/helpers.sh"


[[ "$INIT_CWD" == "$PWD" ]] && exit 0




destination="${INIT_CWD:+$INIT_CWD/}"

rm -rf "$destination/.flint" && mkdir -p "$destination/.flint"

source="$( cd "$(dirname "$0" )/.." && pwd )"




if [[ ! -f "$source/src/wrapper.sh" && ! -d "$source/hooks" ]]

then
    printf "\n\033[0;31mError: Required files not found at [ $source ].\033[0m\n"

    exit 1
fi


path="$source"

if [[ "$1" == "--with-hooks" ]]

then
    cp -r "$source/hooks" "$destination/.flint/hooks"

    path="$destination"
fi


printf "#!/bin/bash

config=\"flint.config.json\"
hooks=\"$( get_relative_path "$destination" "$path/.flint/hooks" )\"

source \"$( get_relative_path "$destination/.flint" "$source/src/wrapper.sh" )\" \"\$@\"" > "$destination/.flint/git.sh"

chmod +x "$destination/.flint/git.sh"
