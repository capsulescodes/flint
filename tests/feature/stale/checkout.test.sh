beforeEach()
{
    LOCAL=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/src" "$LOCAL/.core/src"

    INIT_CWD="$LOCAL" sh "$PWD/dist/init.sh" --hooks > /dev/null

    sed -i "" "s|${PWD}|${LOCAL}/.core|" "$LOCAL/.flint/git.sh"

    sed -i '' $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.core/src/wrapper.sh"

    sed -i "" "s|command git|git|" "$LOCAL/.core/src/wrapper.sh"

    sed -i "" "s|eval_for_command|mock_for_command|" "$LOCAL/.core/src/functions.sh"

    cp "$PWD/tests/fixtures/config.006.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.core/replace"


    cd $LOCAL > /dev/null || exit 1

    source "$LOCAL/.core/src/functions.sh"

    mock $LOCAL

    echo "local" > "$LOCAL/file.001.foo"
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_checks_out_no_modified_file()
{
    # PROCESS

    BRANCH=$( mktemp -d )

    echo "local" > "$BRANCH/file.001.foo"

    output=$( wrap checkout $BRANCH )
    [[ -f "$LOCAL/file.001.foo" ]]
    assert "checkout - Should check out file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "checkout $BRANCH" ]]
    assert "commands - Should use correct checkout command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ -z "$( ls -A "$LOCAL/.git/modified" )" ]]
    assert "files - Modified files should be present"
    [[ -z "$( ls -A "$LOCAL/.git/staged" )" ]]
    assert "files - Staged files should be present"
    [[ -z "$( ls -A "$LOCAL/.git/committed" )" ]]
    assert "files - Committed files should be present"

    rm -r $BRANCH
}


it_checks_out_multiple_modified_file()
{
    # PROCESS

    BRANCH=$( mktemp -d )

    echo "remote" > "$BRANCH/file.001.foo"
    echo "remote" > "$BRANCH/file.002.foo"

    output=$( wrap checkout $BRANCH )
    [[ -f "$LOCAL/file.001.foo" && -f "$LOCAL/file.002.foo" ]]
    assert "checkout - Should check out file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "checkout $BRANCH" ]]
    assert "commands - Should use correct checkout command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct ls-tree command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.002.foo.001" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.002.foo.001" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.002.foo.001|file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"

    rm -r $BRANCH
}


it_creates_a_file_adds_it_then_creates_another_file_and_checks_out_a_modified_file()
{
    # PROCESS

    echo "local" > "$LOCAL/file.001.foo"

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add file"

    echo "local" > "$LOCAL/file.002.foo"

    output=$( git modify file.002.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "local" && -f "$LOCAL/.git/modified/file.002.foo" ]]
    assert "modify - Should modify files"

    BRANCH=$( mktemp -d )

    echo "remote" > "$BRANCH/file.003.foo"

    output=$( wrap checkout $BRANCH )
    [[ -f "$LOCAL/file.003.foo" ]]
    assert "checkout - Should check out file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "local" ]]
    assert "modify - Should unstage file"
    [[ "$( cat "$LOCAL/.git/modified/.file.003.foo.001" )" == "local" ]]
    assert "modify - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.003.foo.001" )" == "local" ]]
    assert "modify - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "pull - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.003.foo.001" )" == "local" && -f "$LOCAL/.git/committed/file.003.foo" ]]
    assert "pull - Should commit file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "pull - Should add staged file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "restore --staged file.001.foo" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "checkout $BRANCH" ]]
    assert "commands - Should use correct checkout command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "ls-tree -r HEAD --long" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.003.foo" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.003.foo" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct ls-tree command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct unstaged command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|file.003.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.002.foo.001|.file.003.foo.001|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.003.foo.001|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.003.foo.001|file.003.foo" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"

    rm -r $BRANCH
}
