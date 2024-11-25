beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/bin/" "$LOCAL/.core/bin"

    cp -r "$PWD/dist/" "$LOCAL/.core/dist"

    cp -r "$PWD/src/" "$LOCAL/.core/src"

    INIT_CWD=$LOCAL sh "$PWD/dist/init.sh" --with-hooks > /dev/null

    sed -i "" "s|${PWD}|${LOCAL}/.core|" "$LOCAL/.flint/git.sh"

    sed -i "" "s|path=\"\$( cd -P \"\$( dirname \$target )\" && pwd )/../dist|path=\"$LOCAL/.core/dist|" "$LOCAL/.core/bin/flint"

    sed -i "" "s|sh \"|source \"|" "$LOCAL/.core/bin/flint"

    sed -i "" "s|source \"\$( cd \"\$( dirname \"\${BASH_SOURCE\[0\]}\" )\" && pwd )/../src/functions.sh\"||" "$LOCAL/.core/dist/run.sh"

    sed -i '' $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.core/src/wrapper.sh"

    sed -i "" "s|command git|git|" "$LOCAL/.core/src/wrapper.sh"

    sed -i "" "s|eval_for_command|mock_for_command|" "$LOCAL/.core/src/functions.sh"

    cp "$PWD/tests/fixtures/config.007.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.core/replace"


    cd $LOCAL > /dev/null || exit 1

    mkdir "$LOCAL/.git"

    source "$LOCAL/.core/src/functions.sh"

    mock $LOCAL

    INIT_CWD=$LOCAL
}

afterEach()
{
    unmock

    cd - > /dev/null || exit 1

    rm -rf $LOCAL
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
    echo $output | grep -q "No binary or 'foo' command associated with a linter. Skipping."
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


it_runs_flint_run_locally_by_default()
{
    echo "remote" > file.001.foo

    output=$( flint run )
    [[ -f "$LOCAL/file.001.foo" ]]
    assert "flint - Should pull file"
    [[ "$( cat "$LOCAL/file.001.foo" )" == "local" ]]
    assert "flint - Should modify file locally"

    rm file.001.foo
}


it_runs_flint_locally_by_default()
{
    echo "remote" > file.001.foo

    output=$( flint )
    [[ -f "$LOCAL/file.001.foo" ]]
    assert "flint - Should pull file"
    [[ "$( cat "$LOCAL/file.001.foo" )" == "local" ]]
    assert "flint - Should modify file locally"

    rm file.001.foo
}


it_runs_flint_with_given_command()
{
    echo "foo" > file.001.foo

    output=$( flint run bar )
    [[ -f "$LOCAL/file.001.foo" ]]
    assert "flint - Should pull file"
    [[ "$( cat "$LOCAL/file.001.foo" )" == "bar" ]]
    assert "flint - Should modify file"

    rm file.001.foo
}


it_creates_a_file_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( flint run )
    [[ -f "$LOCAL/file.001.foo" ]]
    assert "flint - Should pull file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "flint - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]]
    assert "flint - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "flint - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "local" ]]
    assert "flint - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -A "$LOCAL" | grep -Ec "^(.core|.flint|.git|file.001.foo|flint.config.json)$" ) -eq $( ls -A "$LOCAL" | wc -l ) ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -A "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001)$" ) -eq $( ls -A "$LOCAL/.git/modified" | wc -l ) ]]
    assert "files - Modified files should be present"
    [[ $( ls -A "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001)$" ) -eq $( ls -A "$LOCAL/.git/staged" | wc -l ) ]]
    assert "files - Staged files should be present"
    [[ $( ls -A "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|file.001.foo)$" ) -eq $( ls -A "$LOCAL/.git/committed" | wc -l ) ]]
    assert "files - Committed files should be present"

    rm file.001.foo
}

it_creates_a_file_adds_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote" ]]
    assert "add - Should keep file content"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "flint - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" ]]
    assert "flint - Should add file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"

    # DIRECTORIES

    [[ $( ls -A "$LOCAL" | grep -Ec "^(.core|.flint|.git|file.001.foo|flint.config.json)$" ) -eq $( ls -A "$LOCAL" | wc -l ) ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -A "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001)$" ) -eq $( ls -A "$LOCAL/.git/modified" | wc -l ) ]]
    assert "files - Modified files should be present"
    [[ $( ls -A "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|file.001.foo)$" ) -eq $( ls -A "$LOCAL/.git/staged" | wc -l ) ]]
    assert "files - Staged files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote" ]]
    assert "add - Should keep file content"

    output=$( wrap commit -m "foo" )
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint run )
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "flint - Should reset Flint temporary commit"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "flint - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "flint - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-tree command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -A "$LOCAL" | grep -Ec "^(.core|.flint|.git|file.001.foo|flint.config.json)$" ) -eq $( ls -A "$LOCAL" | wc -l ) ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -A "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001)$" ) -eq $( ls -A "$LOCAL/.git/modified" | wc -l ) ]]
    assert "files - Modified files should be present"
    [[ $( ls -A "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq $( ls -A "$LOCAL/.git/staged" | wc -l ) ]]
    assert "files - Staged files should be present"
    [[ $( ls -A "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo)$" ) -eq $( ls -A "$LOCAL/.git/committed" | wc -l ) ]]
    assert "files - Committed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_creates_another_file_adds_it_and_runs_flint()
{
    # PROCESS

    echo "remote" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "first add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "remote" ]]
    assert "first add - Should keep file content"

    output=$( wrap commit -m "foo" )
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    echo "remote" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ -f "$LOCAL/.git/staged/file.002.foo" ]]
    assert "second add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "remote" ]]
    assert "second add - Should keep file content"

    output=$( flint run )
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "local" ]]
    assert "flint - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "local" ]]
    assert "flint - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "flint - Should reset Flint temporary commit"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "flint - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "flint - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-tree command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "restore --staged file.002.foo" ]]
    assert "commands - Should use correct restore command format"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command format"

    # DIRECTORIES

    [[ $( ls -A "$LOCAL" | grep -Ec "^(.core|.flint|.git|file.001.foo|file.002.foo|flint.config.json)$" ) -eq $( ls -A "$LOCAL" | wc -l ) ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -A "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001|.file.002.foo.001)$" ) -eq $( ls -A "$LOCAL/.git/modified" | wc -l ) ]]
    assert "files - Modified files should be present"
    [[ $( ls -A "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.002.foo.001|.file.002.foo.002|file.002.foo)$" ) -eq $( ls -A "$LOCAL/.git/staged" | wc -l ) ]]
    assert "files - Staged files should be present"
    [[ $( ls -A "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo)$" ) -eq $( ls -A "$LOCAL/.git/committed" | wc -l ) ]]
    assert "files - Committed files should be present"

    rm file.001.foo
}
