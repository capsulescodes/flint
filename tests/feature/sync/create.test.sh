beforeEach()
{
    LOCAL=$( mktemp -d )

    REMOTE=$( mktemp -d )


    INIT_CWD="$LOCAL" sh "$PWD/dist/init.sh" --with-hooks > /dev/null

    sed -i "" "s|${PWD}/src|${LOCAL}/.flint|" "$LOCAL/.flint/git.sh"

    cp -r "$PWD/src/" "$LOCAL/.flint"

    sed -i "" "s|command git|git|" "$LOCAL/.flint/wrapper.sh"

    cp "$PWD/tests/fixtures/config.006.json" "$LOCAL/flint.config.json"

    cp "$PWD/tests/fixtures/replace" "$LOCAL/.flint/replace"

    path=$PWD

    cd $LOCAL > /dev/null || exit 1


    mkdir "$LOCAL/.git"

    touch "$LOCAL/.git/commits"

    touch "$LOCAL/.git/commands"


    mock $LOCAL $REMOTE
}

afterEach()
{
    unmock

    cd - > /dev/null || exit 1

    rm -rf $REMOTE

    rm -rf $LOCAL
}




it_creates_a_file_adds_it_commit_it_and_push()
{
    # PROCESS

    echo "local" > "file.001.foo"


    output=$( flint add file.001.foo )
    [[ -e  "$LOCAL/.git/staged/file.001.foo" ]]
    assert "add - Should add created file"

    output=$( flint commit -m "foo" )
    [ "$( cat "$LOCAL/.git/staged/.file.001.foo.001" )" == "local" ]
    assert "commit : 1 - Should format remotely"
    [[ "$( head -n 1 "$LOCAL/.git/commits" )" == "foo" ]]
    assert "commit : 2 - Should commit with message"
    [ "$( cat "$LOCAL/.git/committed/.file.001.foo.001" )" == "remote" ]
    assert "commit : 3 - Should format remotely"
    [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-FIX-TEMP-COMMIT" ]]
    assert "commit : 4 - Should commit temporary"
    [ "$( cat "$LOCAL/.git/committed/.file.001.foo.002" )" == "local" ]
    assert "commit : 5 - Should format locally"

    output=$( flint push origin branch )
    [[ "$(tail -n 2 "$LOCAL/.git/commits" | head -n 1 )" == "DELETED-TEMP-COMMIT" ]]
    assert "push : 1 - Should reset Flint temporary commit"
    [ "$( cat "$LOCAL/.git/staged/.file.001.foo.002" )" == "remote" ]
    assert "push : 2 - Should push to remote"
    [[ "$( tail -n 1 "$LOCAL/.git/commits" )" == "FLINT-FIX-TEMP-COMMIT" ]]
    assert "push : 3 - Should commit temporary"

    # COMMANDS

    [[ "$( head -n 1 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands : 1 - Should use correct add command format"
    [[ "$( head -n 2 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-FIX-TEMP-COMMIT --max-count=1" ]]
    assert "commands : 2 - Should use correct rev-list command format"
    [[ "$( head -n 3 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands : 3 - Should use correct diff-filter command format"
    [[ "$( head -n 4 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands : 4 - Should use correct diff command format"
    [[ "$( head -n 5 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands : 5 - Should use correct add command format"
    [[ "$( head -n 6 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m foo" ]]
    assert "commands : 6 - Should use correct commit command format"
    [[ "$( head -n 7 "$LOCAL/.git/commands" | tail -n 1 )" == "diff-tree --diff-filter=d --name-only --no-commit-id -r HEAD" ]]
    assert "commands : 7 - Should use correct diff-filter command format"
    [[ "$( head -n 8 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --name-only" ]]
    assert "commands : 8 - Should use correct diff command format"
    [[ "$( head -n 9 "$LOCAL/.git/commands" | tail -n 1 )" == "add file.001.foo" ]]
    assert "commands : 9 - Should use correct add command format"
    [[ "$( head -n 10 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-FIX-TEMP-COMMIT --quiet" ]]
    assert "commands : 10 - Should use correct commit command format"
    [[ "$( head -n 11 "$LOCAL/.git/commands" | tail -n 1 )" == "rev-list HEAD --invert-grep --grep=FLINT-FIX-TEMP-COMMIT --max-count=1" ]]
    assert "commands : 11 - Should use correct reve-list command format"
    [[ "$( head -n 12 "$LOCAL/.git/commands" | tail -n 1 )" == "reset --soft FLINT-FIX-TEMP-COMMIT --quiet" ]]
    assert "commands : 12 - Should use correct reset command format"
    [[ "$( head -n 13 "$LOCAL/.git/commands" | tail -n 1 )" == "push origin branch" ]]
    assert "commands : 13 - Should use correct push command format"
    [[ "$( head -n 14 "$LOCAL/.git/commands" | tail -n 1 )" == "diff --diff-filter=d --staged --name-only" ]]
    assert "commands : 14 - Should use correct diff-filter command format"
    [[ "$( head -n 15 "$LOCAL/.git/commands" | tail -n 1 )" == "commit -m FLINT-FIX-TEMP-COMMIT --quiet" ]]
    assert "commands : 15 - Should use correct commit command format"

    # RESULTS IN DIRECTORIES

    echo "$( ls -A "$LOCAL" )" | grep -E "(.flint|.git|file.001.foo|flint.config.json)" > /dev/null
    assert "files : 1 - Unstaged files should be present"
    echo "$( ls -A "$LOCAL/.git/staged" )" | grep -E "(.file.001.foo.001|.file.001.foo.002|.file.001.foo.003)" > /dev/null
    assert "files : 2 - Staged files should be present"
    echo "$( ls -A "$LOCAL/.git/committed" )" | grep -E "(.file.001.foo.003|file.001.foo)" > /dev/null
    assert "files : 1 - Committed files should be present"
    echo "$( ls -A "$REMOTE" )" | grep -E "(.file.001.foo.001|.file.001.foo.002)" > /dev/null
    assert "files : 1 - Pushed files should be present"

    rm file.001.foo
}
