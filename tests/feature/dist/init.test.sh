beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir -p "$LOCAL/.core"

    cp -r "$PWD/bin/" "$LOCAL/.core/bin"

    cp -r "$PWD/dist/" "$LOCAL/.core/dist"

    cp -r "$PWD/hooks/" "$LOCAL/.core/hooks"

    cp -r "$PWD/src/" "$LOCAL/.core/src"

    cp -r "$PWD/stubs" "$LOCAL/.core/stubs"

    sed -i.bak -e "s|\$( cd -P \"\$( dirname \$target )\" && pwd )/..|$LOCAL/.core|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/..|$LOCAL/.core|" "$LOCAL/.core/dist/init.sh"


    cd $LOCAL > /dev/null || exit 1

    mock $LOCAL

    INIT_CWD=$LOCAL
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_warns_if_source_hooks_directory_is_missing()
{
    mv "$LOCAL/.core/hooks" "$LOCAL/.core/hooks-bak"

    output=$( flint init )
    [[ ! -d "$LOCAL/.core/hooks" ]]
    assert "Should not have hooks directory"
    echo $output | grep -q "Required files not found at '$LOCAL/.core'."
    assert "Should output message"

    mv "$LOCAL/.core/hooks-bak" "$LOCAL/.core/hooks"
}


it_warns_if_source_hooks_directory_is_missing()
{
    mv "$LOCAL/.core/hooks" "$LOCAL/.core/hooks-bak"

    output=$( flint init )
    [[ ! -d "$LOCAL/.core/hooks" ]]
    assert "Should not have hooks directory"
    echo $output | grep -q "Required files not found at '$LOCAL/.core'."
    assert "Should output message"

    mv "$LOCAL/.core/hooks-bak" "$LOCAL/.core/hooks"
}


it_warns_if_source_wrapper_file_is_missing()
{
    mv "$LOCAL/.core/src/wrapper.sh" "$LOCAL/.core/src/wrapper.sh.bak"

    output=$( flint init )
    [[ ! -f "$LOCAL/.core/wrapper.sh" ]]
    assert "Should not have wrapper file"
    echo $output | grep -q "Required files not found at '$LOCAL/.core'."
    assert "Should output message"

    mv "$LOCAL/.core/src/wrapper.sh.bak" "$LOCAL/.core/src/wrapper.sh"
}


it_creates_flint_directory()
{
    output=$( flint init )
    [[ -d "$LOCAL/.flint" ]]
    assert "Should create flint directory"
    echo $output | grep -q "Directory '.flint' added to project root."
    assert "Should output message"
}


it_skips_flint_directory_creation_if_it_already_exists()
{
    mkdir -p "$LOCAL/.flint"

    output=$( flint init )
    echo $output | grep -q "Directory '.flint' already exists in project root. Skipping."
    assert "Should output message"
}


it_creates_hooks_directory_inside_flint_directory_if_mentionned()
{
    output=$( flint init --hooks )
    [[ -d "$LOCAL/.flint/hooks" ]]
    assert "Should create hooks directory"
    echo "$( cat "$LOCAL/.flint/git.sh" )" | grep -q "hooks=\".flint/hooks\""
    assert "Should modify file"
    echo $output | grep -q "Hooks directory 'hooks' added to '.flint' directory."
    assert "Should output message"
}


it_creates_a_configuration_file()
{
    output=$( flint init )
    [[ -f "$LOCAL/flint.config.json" ]]
    assert "Should create configuration file"
    echo $output | grep -q "Base config file 'flint.config.json' added to project root."
    assert "Should output message"
}


it_skips_configuration_creation_if_mentionned()
{
    output=$( HOME=$LOCAL flint init --no-config )
    [[ ! -f "$LOCAL/flint.config.json" ]]
    assert "Should not create configuration file"
}


it_skips_configuration_file_creation_if_it_already_exists()
{
    touch "$LOCAL/flint.config.json"

    output=$( flint init )
    echo $output | grep -q "Base config file 'flint.config.json' already exists in project root. Skipping."
    assert "Should output message"
}


it_skips_git_wrapper_function_integration_if_not_mentionned()
{
    touch .bash_profile

    output=$( SHELL="bash" HOME=$LOCAL flint init )
    [[ -f "$LOCAL/.bash_profile" && ! -s "$LOCAL/.bash_profile" ]]
    assert "Should be empty"

    rm .bash_profile
}


it_adds_a_git_wrapper_function_in_bash_profile_file()
{
    touch .bash_profile

    output=$( SHELL="bash" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.bash_profile" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    rm .bash_profile

    touch .bashrc

    output=$( SHELL="bash" HOME=$LOCAL flint init --wrap )
    [[ ! -f "$LOCAL/.bash_profile" ]]
    assert "Should not have bash profile file"
    echo "$( cat "$LOCAL/.bashrc" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    rm .bashrc
}


it_skips_git_wrapper_function_addition_if_it_already_exists_in_bash_profile_file()
{
    touch .bashrc

    output=$( SHELL="bash" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.bashrc" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    output=$( SHELL="bash" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Git wrapper function already exists in '.bashrc' file"
    assert "Should add wrapper function inside bash profile file"

    rm .bashrc
}


it_warns_if_no_bash_profile_file_is_found()
{
    output=$( SHELL="bash" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Shell profile file not found. the Git wrapper function is required to use Flint correctly. Please add it manually."
    assert "Should output message"
}


it_adds_a_git_wrapper_function_in_zsh_profile_file()
{
    touch .zshrc

    output=$( SHELL="zsh" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.zshrc" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    rm .zshrc
}


it_skips_git_wrapper_function_addition_if_it_already_exists_in_zsh_profile_file()
{
    touch .zshrc

    output=$( SHELL="zsh" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.zshrc" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    output=$( SHELL="zsh" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Git wrapper function already exists in '.zshrc' file"
    assert "Should add wrapper function inside bash profile file"

    rm .zshrc
}


it_warns_if_no_zsh_profile_file_is_found()
{
    output=$( SHELL="zsh" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Shell profile file not found. the Git wrapper function is required to use Flint correctly. Please add it manually."
    assert "Should output message"
}


it_adds_a_git_wrapper_function_in_fish_profile_file()
{
    mkdir -p .config/fish/config

    touch .config/fish/config.fish

    output=$( SHELL="fish" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.config/fish/config.fish" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    rm -r .config
}


it_skips_git_wrapper_function_addition_if_it_already_exists_in_fish_profile_file()
{
    mkdir -p .config/fish/config

    touch .config/fish/config.fish

    output=$( SHELL="fish" HOME=$LOCAL flint init --wrap )
    echo "$( cat "$LOCAL/.config/fish/config.fish" )" | grep -q "git()"
    assert "Should add wrapper function inside bash profile file"

    output=$( SHELL="fish" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Git wrapper function already exists in 'config.fish' file"
    assert "Should add wrapper function inside bash profile file"

    rm -r .config
}


it_warns_if_no_fish_profile_file_is_found()
{
    output=$( SHELL="fish" HOME=$LOCAL flint init --wrap )
    echo $output | grep -q "Shell profile file not found. the Git wrapper function is required to use Flint correctly. Please add it manually."
    assert "Should output message"
}


it_warns_if_no_shell_is_found()
{
    output=$( SHELL="foo" flint init --wrap )
    echo $output | grep -q "Shell profile file not found. the Git wrapper function is required to use Flint correctly. Please add it manually."
    assert "Should output message"
}
