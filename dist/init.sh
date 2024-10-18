#!/bin/bash

if [[ "$INIT_CWD" == "$PWD" ]]

then
    exit 0
fi


destination="$INIT_CWD/.flint"


if [[ -d "$destination" ]]

then
    rm -rf "$destination"
fi

mkdir  "$destination"



source="$( cd "$(dirname "$0" )/.." && pwd )"

if [[ ! -f "$source/src/wrapper.sh" && ! -d "$source/hooks" ]]

then
    printf "\n\033[0;31mError: Required files not found at [ $source ].\033[0m\n"

    exit 1
fi

path=$source

if [[ "$1" == "--with-hooks" ]]

then
    cp -r "$source/hooks" "$destination/hooks"

    path=$destination
fi


printf "#!/bin/bash

config=\"flint.config.json\"
hooks=\"$path/hooks\"

source \"$source/src/wrapper.sh\" \"\$@\"" > "$destination/git.sh"

chmod +x "$destination/git.sh"
