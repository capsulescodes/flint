#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/helpers.sh"


[[ "$INIT_CWD" == "$PWD" ]] && exit 0




destination="${INIT_CWD:+$INIT_CWD/}.flint"

if [ ! -d "$destination" ]

then
    mkdir -p "$destination"

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

        echo "\033[0;32m[ Flint ] Hooks directory added to \"/.flint\" directory.\033[0m"
    fi

    wrapper="$( get_relative_path "$destination" "$source/src/wrapper.sh" )"




    printf "#!/bin/bash\n\nconfig=\"flint.config.json\"\nhooks=\"$hooks\"\n\nsource \"$wrapper\" \"\$@\"" > "$destination/git.sh"

    chmod +x "$destination/git.sh"

    echo "\033[0;32m[ Flint ] \"/.flint\" directory added to project root.\033[0m"



    config="$PWD/flint.config.json"

    if [ ! -f "$config" ]

    then
        cp "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../template.config.json" "$config"

        echo "\033[0;32m[ Flint ] Base config file added to project root.\033[0m"
    fi
fi




shell=$( basename "$SHELL" )


if [ "$shell" == "bash" ]

then
    if [ -f "$HOME/.bash_profile" ]

    then
        profile="$HOME/.bash_profile"
    else
        profile="$HOME/.bashrc"
    fi
fi

if [ "$shell" == "zsh" ]

then
     profile="$HOME/.zshrc"
fi

if [ "$shell" == "fish" ]

then
    profile="$HOME/.config/fish/config.fish"
fi


if [ -f "$profile" ]

then
    command='git() { [[ -f "$PWD/.flint/git.sh" ]] && source "$PWD/.flint/git.sh" || command git "$@"; }'

    if [[ ! "$( cat "$profile" | tr -d '[:space:]' )" == *"$( echo "$command" | tr -d '[:space:]' )"* ]]

    then
        printf  "\n\n\n\n# Flint git wrapper\n$command\n\n" >> "$profile"

        echo "\033[0;32m[ Flint ] Git wrapper function written in '"$( basename "$profile" )"' file.\033[0m"
    fi
fi
