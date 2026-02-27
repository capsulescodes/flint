beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/bin/" "$LOCAL/.core/bin"

    cp -r "$PWD/dist/" "$LOCAL/.core/dist"

    cp -r "$PWD/src/" "$LOCAL/.core/src"

    INIT_CWD=$LOCAL bash "$PWD/dist/init.sh" --hooks > /dev/null

    sed -i.bak -e "s|${PWD}|${LOCAL}/.core|" "$LOCAL/.flint/git.sh"

    sed -i.bak -e "s|path=\"\$( cd -P \"\$( dirname \"\$target\" )\" && pwd )/../dist|path=\"$LOCAL/.core/dist|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|bash \"|source \"|" "$LOCAL/.core/bin/flint"

    sed -i.bak -e "s|source \"\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/../src/functions.sh\"||" "$LOCAL/.core/dist/run.sh"

    sed -i.bak -e $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|command git|git|" "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|eval_for_command|mock_for_command|" "$LOCAL/.core/src/functions.sh"

    cp "$PWD/tests/fixtures/config.007.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.core/replace"


    cd $LOCAL > /dev/null || exit 1

    source "$LOCAL/.core/src/functions.sh"

    mock $LOCAL

    INIT_CWD=$LOCAL
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_returns_a_warning_if_flint_directory_does_not_exist()
{
    INIT_CWD="foo"

    output=$( flint run )
    echo $output | grep -q "Flint must be configured first. Run 'flint init' to proceed."
    assert "Should output error message"
}


it_returns_a_warning_if_configuration_file_does_not_exist()
{
    rm "$LOCAL/flint.config.json"

    output=$( flint run )
    echo $output | grep -q "The 'flint.config.json' file does not exist in the root directory."
    assert "Should output error message"
}


it_returns_a_warning_if_command_does_not_exist()
{
    output=$( flint run foo )
    echo $output | grep -q "No 'foo' command associated with linter. Skipping."
    assert "Should output error message"
}


it_returns_a_warning_if_binary_file_does_not_exist()
{
    rm "$LOCAL/.core/replace"

    echo "remote" > file.001.foo

    output=$( flint run )
    echo $output | grep -q "Binary '.core/replace' not found. Install it and run 'flint run'. Skipping."
    assert "Should output error message"

    rm file.001.foo
}


it_runs_flint_with_given_command()
{
    echo "foo" > file.001.foo

    output=$( flint run bar )
    [[ "$( cat "$LOCAL/file.001.foo" )" == "bar" ]]
    assert "flint - Should modify file"

    rm file.001.foo
}


it_creates_a_file_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( git modify "file.001.foo" )
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.001")" == "remote" && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == "remote" ]]
    assert "modify - Should create file"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == "local" ]]
    assert "run - Should modify file locally"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo "" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo "" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote"  && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "remote" ]]
    assert "add - Should add file"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "run - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "run - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "run - Should add file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "restore --staged file.001.foo" ]]
    assert "commands - Should use correct restore command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "remote"  ]]
    assert "add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "run - Should reset temporary commit"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "run - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "run - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_creates_another_file_adds_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote"  && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "remote" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"

    echo "remote" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "remote" ]]
    assert "second add - Should add file"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "run - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote" ]]
    assert "run - Should restore file"
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "run - Should modify file locally"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "run - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "run - Should commit file"
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "local" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local"  ]]
    assert "run - Should add file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "restore --staged file.002.foo" ]]
    assert "commands - Should use correct restore command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_modifies_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote"  && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "remote" ]]
    assert "add - Should add file"

    echo "remote" >> file.001.foo

    output=$( wrap modify file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "remote"  ]]
    assert "modify - Should keep added file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == $'remote\nremote'  && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'remote\nremote' ]]
    assert "modify - Should modify file"

    output=$( flint run )

    [[ "$( cat "$LOCAL/.git/patched/.file.001.foo.001" )" == $'remote\nremote' ]]
    assert "run - Should patch file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "remote" ]]
    assert "run - Should restore file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "local" ]]
    assert "run - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local"  && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "run - Should add file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == $'local\nlocal' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nlocal' ]]
    assert "run - Should unpatch file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff file.001.foo" ]]
    assert "commands - Should use correct diff command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "commands - Should use correct hash-object command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "stash push --keep-index --quiet -- file.001.foo" ]]
    assert "commands - Should use correct stash command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "restore --staged file.001.foo" ]]
    assert "commands - Should use correct restore command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "cat-file -p patched" ]]
    assert "commands - Should use correct cat-file command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "apply" ]]
    assert "commands - Should use correct apply command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/patched" )" == "$( echo ".file.001.foo.001" | tr "|" "\n" )" ]]
    assert "files - Patched files should be present"

    rm file.001.foo
}
