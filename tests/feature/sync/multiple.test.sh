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




it_creates_two_files_add_them_commit_them_and_push_them()
{
    # PROCESS

    echo "local" > file.001.foo
    echo "local" > file.002.foo

    output=$( wrap add file.001.foo file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local" ]]
    assert "add - Should add files"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote" ]]
    assert "commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "commit - Should add files"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.002.foo" )" == "remote" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local" ]]
    assert "commit - Should commit files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should reset files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" &&  "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local" ]]
    assert "commit - Should commit files"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
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

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_commits_it_creates_another_file_adds_it_commits_it_and_push_them()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "first commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "first commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "first commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "first commit - Should commit file"

    echo "local" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local" ]]
    assert "second add - Should add file"

    output=$( wrap commit -m "BAR" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "commit - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote" ]]
    assert "second commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "BAR" ]]
    assert "second commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/committed/BAR/file.001.foo" )" == "remote" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/BAR/file.002.foo" )" == "remote" ]]
    assert "second commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "second commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should add files"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local" ]]
    assert "commit - Should commit files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local" ]]
    assert "commit - Should reset files"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" ]]
    assert "commit - Should commit files"

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
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m BAR" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command"
    [[ "$( head -n 37 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|BAR|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/BAR" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed BAR files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_commits_it_pushes_it_creates_another_file_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "first commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "first commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote" ]]
    assert "first commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "first commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "first commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "first commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "first commit - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" ]]
    assert "first push - Should commit file"

    echo "local" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "BAR" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == "local" ]]
    assert "first commit - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "first commit - Should add files"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "BAR" ]]
    assert "second commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == "remote" && "$( cat "$LOCAL/.git/committed/BAR/file.001.foo" )" == "remote" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/BAR/file.002.foo" )" == "remote" ]]
    assert "second commit - Should commit files"
    [[  "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "first commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "first commit - Should add files"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local" ]]
    assert "second commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.008" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local" ]]
    assert "first commit - Should reset files"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 6 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.006" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local" ]]
    assert "second commit - Should commit file"

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
    assert "commands - Should use correct committed command"
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
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m BAR" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 37 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 38 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 39 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 40 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 41 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 42 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 43 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.001.foo.008|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|BAR|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/BAR" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed BAR files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_creates_another_file_adds_it_modifies_a_file_commits_them_and_push_them()
{
    # PROCESS

    echo "local foo" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local foo" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local foo" ]]
    assert "first add - Should add file"

    echo "local bar" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local bar" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local bar" ]]
    assert "second add - Should add file"

    echo "local" >> file.001.foo

    output=$( wrap modify file.001.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == $'local foo\nlocal' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local foo\nlocal' ]]
    assert "modify - Should modify file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/patched/.file.001.foo.001" )" == $'local foo\nlocal' ]]
    assert "commit - Should patch file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "remote foo" && "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote bar" ]]
    assert "commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote bar" ]]
    assert "commit - Should add files"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote foo" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote bar" &&  "$( cat "$LOCAL/.git/committed/FOO/file.002.foo" )" == "remote bar" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local bar" ]]
    assert "commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local bar" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local bar" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local bar" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local foo\nlocal' ]]
    assert "commit - Should unpatch file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local bar" ]]
    assert "push - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local bar" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local bar" ]]
    assert "push - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff file.001.foo" ]]
    assert "commands - Should use correct diff command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "commands - Should use correct hash-object command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "stash push --keep-index --quiet -- file.001.foo" ]]
    assert "commands - Should use correct stash command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "cat-file -p patched" ]]
    assert "commands - Should use correct cat-file command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "apply" ]]
    assert "commands - Should use correct apply command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/patched" )" == "$( echo ".file.001.foo.001" | tr "|" "\n" )" ]]
    assert "files - Patched files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_creates_another_file_modifies_a_file_commits_them_and_push_them()
{
    # PROCESS

    echo "local foo" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local foo" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local foo" ]]
    assert "add - Should add file"

    echo "local bar" > file.002.foo

    output=$( wrap modify file.002.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "local bar" && "$( cat "$LOCAL/.git/modified/file.002.foo" )" == "local bar" ]]
    assert "first modify - Should modify file"

    echo "local" >> file.002.foo

    output=$( wrap modify file.002.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == $'local bar\nlocal' && "$( cat "$LOCAL/.git/modified/file.002.foo" )" == $'local bar\nlocal' ]]
    assert "second modify - Should modify file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote foo" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote foo" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote foo" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote foo" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local foo" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" ]]
    assert "commit - Should commit files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local foo" ]]
    assert "push - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" ]]
    assert "push - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct modify command"
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

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.002.foo.001|.file.002.foo.002|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ -z "$( ls -A "$LOCAL/.git/patched" )" ]]
    assert "files - Patched files should be absent"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_creates_another_file_adds_it_modifies_two_files_commits_them_and_pushes_them()
{
    # PROCESS

    echo "local foo" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local foo" && "$( cat "$LOCAL/.git/staged/file.001.foo" )" == "local foo" ]]
    assert "first add - Should add file"

    echo "local bar" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local bar" && "$( cat "$LOCAL/.git/staged/file.002.foo" )" == "local bar" ]]
    assert "second add - Should add file"

    echo "local baz" >> file.001.foo

    output=$( wrap modify file.001.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == $'local foo\nlocal baz' && "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local foo\nlocal baz' && "$( cat "$LOCAL/file.001.foo" )" == $'local foo\nlocal baz' ]]
    assert "first modify - Should modify file"

    echo "local qux" >> file.002.foo

    output=$( wrap modify file.002.foo )
    [[ "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == $'local bar\nlocal qux' && "$( cat "$LOCAL/.git/modified/file.002.foo" )" == $'local bar\nlocal qux' && "$( cat "$LOCAL/file.002.foo" )" == $'local bar\nlocal qux' ]]
    assert "second modify - Should modify file"

    output=$( wrap commit -m "FOO" )
    [[ "$( cat "$LOCAL/.git/patched/.file.001.foo.001" )" == $'local foo\nlocal baz' && "$( cat "$LOCAL/.git/patched/.file.002.foo.001" )" == $'local bar\nlocal qux' ]]
    assert "commit - Should patch files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "remote foo" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "remote bar" ]]
    assert "commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote bar" ]]
    assert "commit - Should add files"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "FOO" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote foo" && "$( cat "$LOCAL/.git/committed/FOO/file.001.foo" )" == "remote foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote bar" && "$( cat "$LOCAL/.git/committed/FOO/file.002.foo" )" == "remote bar" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/modified/.file.002.foo.003" )" == "local bar" ]]
    assert "commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local bar" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local bar" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local bar" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/file.001.foo" )" == $'local foo\nlocal baz' && "$( cat "$LOCAL/.git/modified/file.002.foo" )" == $'local bar\nlocal qux' ]]
    assert "commit - Should unpatch files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local foo" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local bar" ]]
    assert "push - Should reset files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local foo" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.001.foo" )" == "local foo" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local bar" && "$( cat "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT/file.002.foo" )" == "local bar" ]]
    assert "push - Should commit files"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.002.foo" ]]
    assert "commands - Should use correct modify command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct unstaged command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff file.001.foo file.002.foo" ]]
    assert "commands - Should use correct diff command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "hash-object -w --stdin" ]]
    assert "commands - Should use correct hash-object command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "stash push --keep-index --quiet -- file.001.foo file.002.foo" ]]
    assert "commands - Should use correct stash command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FOO" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "cat-file -p patched" ]]
    assert "commands - Should use correct cat-file command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "apply" ]]
    assert "commands - Should use correct apply command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|FLINT-TEMPORARY-COMMIT|FOO" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FLINT-TEMPORARY-COMMIT" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FLINT-TEMPORARY-COMMIT files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed/FOO" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed FOO files should be present"
    [[ "$( ls -A "$LOCAL/.git/patched" )" == "$( echo ".file.001.foo.001|.file.002.foo.001" | tr "|" "\n" )" ]]
    assert "files - Patched files should be absent"
    [[ "$( ls -A "$REMOTE" )" == "$( echo "file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}
