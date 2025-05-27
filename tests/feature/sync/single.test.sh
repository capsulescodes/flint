beforeEach()
{
    LOCAL=$( mktemp -d )

    REMOTE=$( mktemp -d )


    mkdir "$LOCAL/.core"

    cp -r "$PWD/src" "$LOCAL/.core/src"

    INIT_CWD="$LOCAL" bash "$PWD/dist/init.sh" --hooks > /dev/null

    sed -i.bak -e "s|${PWD}|${LOCAL}/.core|" "$LOCAL/.flint/git.sh"

    sed -i.bak -e $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|command git|git|" "$LOCAL/.core/src/wrapper.sh"

    sed -i.bak -e "s|eval_for_command|mock_for_command|" "$LOCAL/.core/src/functions.sh"

    cp "$PWD/tests/fixtures/config.006.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.core/replace"


    cd $LOCAL > /dev/null || exit 1

    source "$LOCAL/.core/src/functions.sh"

    mock $LOCAL $REMOTE
}

afterEach()
{
    unmock $LOCAL

    cd - > /dev/null || exit 1

    [[ -n "$REMOTE" && -d "$REMOTE" ]] && rm -r $REMOTE

    [[ -n "$LOCAL" && -d "$LOCAL" ]] && rm -r $LOCAL
}




it_creates_a_file_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "push - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "push - Should commit file"

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
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "add - Should add file"

    echo "foo" >> file.001.foo

    output=$( git modify file.001.foo )
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.001")" == $'local\nfoo' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nfoo' ]]
    assert "modify - Should modify file"

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == $'local\nfoo' ]]
    assert "add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == $'remote\nfoo' ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == $'remote\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == $'remote\nfoo' && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == $'local\nfoo' ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == $'local\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == $'local\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "push - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"

    echo "foo" >> "file.001.foo"

    output=$( git modify file.001.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nfoo' ]]
    assert "modify - Should modify file"

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == $'local\nfoo' ]]
    assert "add - Should add file"

    output=$( wrap commit -m "BAR" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == "local" ]]
    assert "commit - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == $'remote\nfoo' ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == $'remote\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "BAR" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == $'remote\nfoo' && "$( cat "$LOCAL/.git/committed/BAR/file.001.foo" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.005" )" == $'local\nfoo' ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == $'local\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.008" )" == $'local\nfoo' ]]
    assert "push - Should reset file"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "push - Should commit file"

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
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct diff command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m BAR" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 37 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 38 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.001.foo.008" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|BAR|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/BAR" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed BAR files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_pushes_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "push - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "push - Should commit file"

    echo "foo" >> file.001.foo

    output=$( git modify file.001.foo )
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.003")" == $'local\nfoo' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nfoo' ]]
    assert "modify - Should modify file"

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == $'local\nfoo' ]]
    assert "add - Should add file"

    output=$( wrap commit -m "BAR" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == 'local' ]]
    assert "commit - Should reset obsolete file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == $'remote\nfoo' ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == $'remote\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "BAR" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == $'remote\nfoo' && "$( cat "$LOCAL/.git/committed/BAR/file.001.foo" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.005" )" == $'local\nfoo' ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.008" )" == $'local\nfoo' ]]
    assert "commit - Should add file"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.009" )" == $'local\nfoo' ]]
    assert "push - Should reset file"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 6 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.006" )" == $'local\nfoo' && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == $'local\nfoo' ]]
    assert "push - Should commit file"

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
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m BAR" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 37 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 38 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 39 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 40 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 41 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 42 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 43 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 44 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.001.foo.008|.file.001.foo.009" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|BAR|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/BAR" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed BAR files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_modifies_it_commits_it_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "add - Should add file"

    echo "local" >> file.001.foo

    output=$( wrap modify file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "modify - Should move add file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == $'local\nlocal' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nlocal' ]]
    assert "modify - Should modify file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/patched/.file.001.foo.001" )" == $'local\nlocal' ]]
    assert "commit - Should patch file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local\nlocal' ]]
    assert "commit - Should unpatch file"

    output=$( wrap push origin branch )

    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "push - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "push - Should commit file"
    [[ "$( cat "$REMOTE/file.001.foo" )" == "remote" ]]
    assert "push - Should push file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff file.001.foo" ]]
    assert "commands - Should use correct diff command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "commands - Should use correct hash-object command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "stash push -- file.001.foo" ]]
    assert "commands - Should use correct stash command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "cat-file -p patched" ]]
    assert "commands - Should use correct cat-file command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "apply" ]]
    assert "commands - Should use correct apply command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/patched" )" == "$( echo ".file.001.foo.001" | tr "|" "\n" )" ]]
    assert "files - Patched files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}
