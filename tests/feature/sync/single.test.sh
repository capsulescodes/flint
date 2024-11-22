beforeEach()
{
    LOCAL=$( mktemp -d )

    REMOTE=$( mktemp -d )


    INIT_CWD="$LOCAL" sh "$PWD/dist/init.sh" --with-hooks > /dev/null

    sed -i "" "s|${PWD}/src|${LOCAL}/.flint|" "$LOCAL/.flint/git.sh"

    cp -r "$PWD/src/" "$LOCAL/.flint"

    sed -i '' $'/^else$/ { N; N; s|else\\n[[:space:]]*source.*\\nfi|fi|; }' "$LOCAL/.flint/wrapper.sh"

    sed -i "" "s|command git|git|" "$LOCAL/.flint/wrapper.sh"

    sed -i "" "s|eval_for_local|mock_for_local|" "$LOCAL/.flint/functions.sh"

    sed -i "" "s|eval_for_remote|mock_for_remote|" "$LOCAL/.flint/functions.sh"

    cp "$PWD/tests/fixtures/config.006.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.flint/replace"

    path=$PWD

    cd $LOCAL > /dev/null || exit 1


    mkdir "$LOCAL/.git"

    source "$LOCAL/.flint/functions.sh"

    mock $LOCAL $REMOTE
}

afterEach()
{
    unmock

    cd - > /dev/null || exit 1

    rm -rf $REMOTE

    rm -rf $LOCAL
}




it_creates_a_file_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > "file.001.foo"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "commit - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "push - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint push origin branch )
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "push - Should reset Flint temporary commit"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct reve-list command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -a "$LOCAL" | grep -Ec "^(.flint|.git|file.001.foo|flint.config.json)$" ) -eq 4 ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -a "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Modified files should be present"
    [[ $( ls -a "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003)$" ) -eq 3 ]]
    assert "files - Staged files should be present"
    [[ $( ls -a "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo)$" ) -eq 4 ]]
    assert "files - Committed files should be present"
    [[ $( ls -a "$REMOTE" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > "file.001.foo"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]]
    assert "add - Should keep file content"

    echo "foo" >> "file.001.foo"

    output=$( git modify "file.001.foo" )
    [[ -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should modify file"
    [[ ! -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should unstage file"
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.001")" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add modified file"
    [[ ! -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should stage file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == $'remote\nfoo' ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == $'remote\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.003" )" == $'local\nfoo' ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == $'local\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint push origin branch )
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "push - Should reset Flint temporary commit"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct reve-list command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command format"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -a "$LOCAL" | grep -Ec "^(.flint|.git|file.001.foo|flint.config.json)$" ) -eq 4 ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -a "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Modified files should be present"
    [[ $( ls -a "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003)$" ) -eq 3 ]]
    assert "files - Staged files should be present"
    [[ $( ls -a "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo)$" ) -eq 4 ]]
    assert "files - Committed files should be present"
    [[ $( ls -a "$REMOTE" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}


it_creates_a_file_adds_it_commits_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > "file.001.foo"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "push - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "push - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    echo "foo" >> "file.001.foo"

    output=$( git modify "file.001.foo" )
    [[ -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should modify file"
    [[ ! -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should unstage file"
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.003")" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add modified file"
    [[ ! -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should stage file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "bar" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == $'remote\nfoo' ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == $'remote\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "bar" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.005" )" == $'local\nfoo' ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == $'local\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint push origin branch )
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "push - Should reset Flint temporary commit"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m bar" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command format"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -a "$LOCAL" | grep -Ec "^(.flint|.git|file.001.foo|flint.config.json)$" ) -eq 4 ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -a "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Modified files should be present"
    [[ $( ls -a "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003)$" ) -eq 3 ]]
    assert "files - Staged files should be present"
    [[ $( ls -a "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|file.001.foo)$" ) -eq 4 ]]
    assert "files - Committed files should be present"
    [[ $( ls -a "$REMOTE" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002)$" ) -eq 2 ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}



it_creates_a_file_adds_it_commits_it_pushed_it_modifies_it_adds_it_commits_it_and_pushes_it()
{
    # PROCESS

    echo "local" > "file.001.foo"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "foo" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should modify file remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]]
    assert "push - Should add file"
    [[ "$( head -n 1 "$LOCAL/.git/commits" | tail -n 1 )" == "foo" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.002" )" == "local" ]]
    assert "commit - Should modify file locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.003" )" == "local" ]]
    assert "push - Should add file"
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint push origin branch )
    [[ "$( head -n 2 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "push - Should reset Flint temporary commit"
    [[ "$( head -n 3 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.003" )" == "local" && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    echo "foo" >> "file.001.foo"

    output=$( git modify "file.001.foo" )
    [[ -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should modify file"
    [[ ! -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should unstage file"
    [[ "$(cat "$LOCAL/.git/modified/.file.001.foo.003")" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint add file.001.foo )
    [[ -f "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add modified file"
    [[ ! -f "$LOCAL/.git/modified/file.001.foo" ]]
    assert "add - Should stage file"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.004" )" == $'local\nfoo' ]]
    assert "add - Should keep file content"

    output=$( flint commit -m "bar" )
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.004" )" == $'remote\nfoo' ]]
    assert "commit - Should modify remotely"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.005" )" == $'remote\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 4 "$LOCAL/.git/commits" | tail -n 1 )" == "bar" ]]
    assert "commit - Should commit with message"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.004" )" == $'remote\nfoo' ]]
    assert "commit - Should commit file"
    [[ "$( cat "$LOCAL/.git/modified/.file.001.foo.005" )" == $'local\nfoo' ]]
    assert "commit - Should modify locally"
    [[ "$( cat "$LOCAL/.git/staged/.file.001.foo.006" )" == $'local\nfoo' ]]
    assert "push - Should add file"
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "commit - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.005" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    output=$( flint push origin branch )
    [[ "$( head -n 5 "$LOCAL/.git/commits" | tail -n 1 )" == "DELETED-TEMPORARY-COMMIT" ]]
    assert "push - Should reset Flint temporary commit"
    [[ "$( head -n 6 "$LOCAL/.git/commits" | tail -n 1 )" == "FLINT-TEMPORARY-COMMIT" ]]
    assert "push - Should commit temporary"
    [[ "$( cat "$LOCAL/.git/committed/.file.001.foo.006" )" == $'local\nfoo' && -f "$LOCAL/.git/committed/file.001.foo" ]]
    assert "commit - Should commit file"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command format"
    [[ "$( head -n 16 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 17 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 18 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify command format"
    [[ "$( head -n 19 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 20 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 21 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 22 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 23 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify remotely command format"
    [[ "$( head -n 24 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 25 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 26 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m bar" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 27 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 28 "$LOCAL/.git/commands" | tail -n 1 )" == "modify file.001.foo" ]]
    assert "commands - Should use correct modify locally command format"
    [[ "$( head -n 29 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands - Should use correct diff command format"
    [[ "$( head -n 30 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands - Should use correct add command format"
    [[ "$( head -n 31 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"
    [[ "$( head -n 32 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-TEMPORARY-COMMIT --max-count=1" ]]
    assert "commands - Should use correct rev-list command format"
    [[ "$( head -n 33 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct reset command format"
    [[ "$( head -n 34 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands - Should use correct push command format"
    [[ "$( head -n 35 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands - Should use correct diff-filter command format"
    [[ "$( head -n 36 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-TEMPORARY-COMMIT --quiet" ]]
    assert "commands - Should use correct commit command format"

    # DIRECTORIES

    [[ $( ls -a "$LOCAL" | grep -Ec "^(.flint|.git|file.001.foo|flint.config.json)$" ) -eq 4 ]]
    assert "files - Unstaged files should be present"
    [[ $( ls -a "$LOCAL/.git/modified" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005)$" ) -eq 5 ]]
    assert "files - Modified files should be present"
    [[ $( ls -a "$LOCAL/.git/staged" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006)$" ) -eq 6 ]]
    assert "files - Staged files should be present"
    [[ $( ls -a "$LOCAL/.git/committed" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005|.file.001.foo.006|file.001.foo)$" ) -eq 7 ]]
    assert "files - Committed files should be present"
    [[ $( ls -a "$REMOTE" | grep -Ec "^(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003|.file.001.foo.004|.file.001.foo.005)$" ) -eq 5 ]]
    assert "files - Pushed files should be present"

    rm file.001.foo
}
