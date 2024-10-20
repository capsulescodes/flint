#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/helpers.sh"


[[ "$INIT_CWD" == "$PWD" ]] && exit 0




destination="${INIT_CWD:+$INIT_CWD/}.flint"

rm -rf "$destination" && mkdir -p "$destination"

source="$( cd "$(dirname "$0" )/.." && pwd )"




if [[ ! -f "$source/src/wrapper.sh" && ! -d "$source/hooks" ]]

then
    printf "\n\033[0;31mError: Required files not found at [ $source ].\033[0m\n"

    exit 1
fi


hooks="$( get_relative_path "$destination" "$source" )/hooks"

if [[ "$1" == "--with-hooks" ]]

then
    cp -r "$source/hooks" "$destination/hooks"

    hooks="$( get_relative_path "$destination" "$destination" ).flint/hooks"
fi

wrapper="$( get_relative_path "$destination" "$source/src/wrapper.sh" )"




printf "#!/bin/bash

config=\"flint.config.json\"
hooks=\"$hooks\"

source \"$wrapper\" \"\$@\"" > "$destination/git.sh"

chmod +x "$destination/git.sh"
