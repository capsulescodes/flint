#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/helpers.sh"


[[ "$INIT_CWD" == "$PWD" ]] && exit 0




if [ "$1" == "init" ]

then
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

        if [[ "$2" == "--with-hooks" ]]

        then
            if [ ! -d "$destination/hooks" ]

            then
                cp -r "$source/hooks" "$destination/hooks"

                echo "\n\033[1;32m[ Flint ] Hooks directory 'hooks' added to \"/.flint\" directory.\033[0m"
            else
                echo "\n\033[1;36m[ Flint ] Hooks directory 'hooks' already exists in \"/.flint\" directory. Skipping.\033[0m"
            fi

            hooks=".flint/hooks"
        fi


        wrapper="$( get_relative_path "$INIT_CWD" "$source/src/wrapper.sh" )"

        printf "#!/bin/bash\n\nconfig=\"flint.config.json\"\nhooks=\"$hooks\"\n\nsource \"$( [[ "$wrapper" == /* ]] && echo "$wrapper" || echo "\$PWD/$wrapper" )\" \"\$@\"" > "$destination/git.sh"

        chmod +x "$destination/git.sh"




        config="${INIT_CWD:-.}/flint.config.json"

        if [ ! -f "$config" ]

        then
            cp "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../template.config.json" "$config"

            echo "\033[1;32m[ Flint ] Base config file 'flint.config.json' added to project root.\033[0m"
        else
            echo "\033[1;36m[ Flint ] Base config file 'flint.config.json' already exists in project root. Skipping.\033[0m"
        fi

        echo "\033[1;32m[ Flint ] \"/.flint\" directory added to project root.\033[0m"
    else
        echo "\033[1;36m[ Flint ] \"/.flint\" directory already exists in project root. Skipping.\033[0m"
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

            echo "\033[1;32m[ Flint ] Git wrapper function written in '"$( basename "$profile" )"' file.\033[0m\n"
        else
            echo "\033[1;36m[ Flint ] Git wrapper function already exists in '"$( basename "$profile" )"' file. Skipping.\033[0m\n"
        fi
    fi




else
    echo "\n\033[1;33m[ Flint ] The 'init' argument is mandatory to run Flint init command. Skipping.\033[0m\n"
fi
