#!/bin/bash

source "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../src/helpers.sh"




destination="${INIT_CWD:+$INIT_CWD/}.flint"

if [ ! -d $destination ]

then
    source="$( cd "$(dirname $0 )/.." && pwd )"

    if [[ ! -f "$source/src/wrapper.sh" || ! -d "$source/hooks" ]]

    then
        printf "\n\033[0;31mflint - Required files not found at '$source'.\033[0m\n"

        exit 1
    fi




    mkdir -p $destination

    printf "\n\033[1;32mflint - Directory '.flint' added to project root.\033[0m\n"




    hooks="$( get_relative_path "$INIT_CWD" "$source" )/hooks"

    if [[ $@ =~ "--with-hooks" ]]

    then
        cp -r "$source/hooks" "$destination/hooks"

        hooks=".flint/hooks"

        printf "\033[1;32mflint - Hooks directory 'hooks' added to '.flint' directory.\033[0m\n"
    fi




    wrapper="$( get_relative_path "$INIT_CWD" "$source/src/wrapper.sh" )"

    printf "#!/bin/bash\n\nconfig=\"flint.config.json\"\nhooks=\"$hooks\"\nwrapper=\"$( [[ $wrapper == /* ]] && echo $wrapper || echo "\$PWD/$wrapper" )\"\n\nif [[ -f \$wrapper ]]; then source \$wrapper; else command git \"\$@\"; fi;" > "$destination/git.sh"

    chmod +x "$destination/git.sh"
else
    printf "\n\033[1;36mflint - Directory '.flint' already exists in project root. Skipping.\033[0m\n"
fi




if [[ ! $@ =~ "--no-config" ]]

then
    config="${INIT_CWD:-.}/flint.config.json"

    if [ ! -f "$config" ]

    then
        cp "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/../template.config.json" $config

        printf "\033[1;32mflint - Base config file 'flint.config.json' added to project root.\033[0m\n"
    else
        printf "\033[1;36mflint - Base config file 'flint.config.json' already exists in project root. Skipping.\033[0m\n"
    fi
fi




if [[ ! $@ =~ "--no-wrap" ]]

then
    shell=$( basename $SHELL )


    if [ $shell == "bash" ]

    then
        if [ -f "$HOME/.bash_profile" ]

        then
            profile="$HOME/.bash_profile"
        fi

        if [ -f "$HOME/.bashrc" ]

        then
            profile="$HOME/.bashrc"
        fi
    fi

    if [ $shell == "zsh" ]

    then
        profile="$HOME/.zshrc"
    fi

    if [ $shell == "fish" ]

    then
        profile="$HOME/.config/fish/config.fish"
    fi


    if [ -f "$profile" ]

    then
        command='git() { if [[ -f "$PWD/.flint/git.sh" ]]; then sh "$PWD/.flint/git.sh" "$@"; else command git "$@"; fi; }'


        if [[ ! "$( cat $profile | tr -d '[:space:]' )" == *"$( echo $command | tr -d '[:space:]' )"* ]]

        then
            printf "\n\n\n\n# Flint git wrapper\n$command\n\n" >> $profile

            printf "\033[1;32mflint - Git wrapper function written in '$( basename $profile )' file.\033[0m\n\n"
        else
            printf "\033[1;36mflint - Git wrapper function already exists in '$( basename $profile )' file. Skipping.\033[0m\n\n"
        fi
    else
        printf "\033[1;33mflint - Shell profile file not found. the Git wrapper function is required to use Flint correctly. Please add it manually.\033[0m\n\n"
    fi
else
    printf "\033[1;30mflint - Git wrapper function not required. Skipping..\033[0m\n"
fi

exit 0
