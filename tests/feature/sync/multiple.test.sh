beforeEach()
{
    LOCAL=$( mktemp -d )

    REMOTE=$( mktemp -d )


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
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.001.foo" && -f "$LOCAL/.git/staged/file.002.foo" ]]
    assert "first add - Should add file"


    output=$( wrap commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote" ]]
    assert "commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "commit - Should add files"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote" ]]
    assert "commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "commit - Should commit files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should reset files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "commit - Should commit files"

    # # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_commits_it_creates_another_file_adds_it_commits_it_and_push_them()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "first commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "first commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "first commit - Should commit file"

    echo "local" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.002.foo" ]]
    assert "second add - Should add file"

    output=$( wrap commit -m "bar" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "commit - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.002.foo.001" )" == "remote" ]]
    assert "second commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "commit - Should add files"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "bar" ]]
    assert "second commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote" ]]
    assert "second commit - Should commit files"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "second commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "commit - Should add files"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "commit - Should commit files"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local" ]]
    assert "commit - Should reset files"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "commit - Should commit files"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m bar" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Modified files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}


it_creates_a_file_adds_it_commits_it_pushes_it_creates_another_file_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > file.001.foo

    output=$( wrap add file.001.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "first commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "first commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "first commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "first commit - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "first commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == "local" ]]
    assert "first commit - Should reset file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "first push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "first push - Should commit file"

    echo "local" > file.002.foo

    output=$( wrap add file.002.foo )
    [[ "$( cat "$LOCAL/.git/staged/.file.002.foo.001" )" == "local" && -f "$LOCAL/.git/staged/file.002.foo" ]]
    assert "first add - Should add file"

    output=$( wrap commit -m "bar" )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == "local" ]]
    assert "first commit - Should reset file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == "remote" && "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "first commit - Should modify files remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == "remote" && "$( cat "$LOCAL/.git/staged/.file.002.foo.002" )" == "remote" ]]
    assert "first commit - Should add files"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "bar" ]]
    assert "second commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == "remote" && "$( cat "$LOCAL/.git/committed/.file.002.foo.001" )" == "remote" ]]
    assert "second commit - Should commit files"
    [[  "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == "local" && "$( cat "$LOCAL/.git/modified/.file.002.foo.002" )" == "local" ]]
    assert "first commit - Should modify files locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.007" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.003" )" == "local" ]]
    assert "first commit - Should add files"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "second commit - Should commit file"

    output=$( wrap push origin branch )
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.008" )" == "local" && "$( cat "$LOCAL/.git/staged/.file.002.foo.004" )" == "local" ]]
    assert "first commit - Should reset files"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" && "$( head -n 6 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "second push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.006" )" == "local" && "$( cat "$LOCAL/.git/committed/.file.002.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" && -f "$LOCAL/.git/committed/file.002.foo" ]]
    assert "second commit - Should commit file"

    # # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify remotely command"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m bar" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct committed command"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo file.002.foo" ]]
    assert "commands - Should use correct modify locally command"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --name-only" ]]
    assert "commands - Should use correct modified command"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo file.002.foo" ]]
    assert "commands - Should use correct add command"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command"
    [[ "$( head -n 37 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command"
    [[ "$( head -n 38 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --staged --name-only" ]]
    assert "commands - Should use correct staged command"
    [[ "$( head -n 39 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command"

    # DIRECTORIES

    [[ "$( ls -A "$LOCAL" )" == "$( echo ".core|.flint|.git|file.001.foo|file.002.foo|flint.config.json" | tr "|" "\n" )" ]]
    assert "files - Unstaged files should be present"
    [[ "$( ls -A "$LOCAL/.git/modified" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/staged" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.001.foo.007|.file.001.foo.008|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|.file.002.foo.004" | tr "|" "\n" )" ]]
    assert "files - Staged files should be present"
    [[ "$( ls -A "$LOCAL/.git/committed" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|.file.002.foo.001|.file.002.foo.002|.file.002.foo.003|file.001.foo|file.002.foo" | tr "|" "\n" )" ]]
    assert "files - Committed files should be present"
    [[ "$( ls -A "$REMOTE" )" == "$( echo ".file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.002.foo.001|.file.002.foo.002" | tr "|" "\n" )" ]]
    assert "files - Pushed files should be present"

    rm file.001.foo file.002.foo
}
