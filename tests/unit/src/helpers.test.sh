beforeAll()
{
    source "$PWD/src/helpers.sh"

    TEST=$( mktemp -d )

    cd "$TEST" > /dev/null || exit 1

    mkdir -p foo/bar
    mkdir -p baz/qux

    touch foo/file.001.txt
    touch baz/file.002.txt
}

afterAll()
{
    cd - > /dev/null || exit 1

    rm -rf "$TEST"
}




it_handles_same_directory()
{
    result=$( get_relative_path "$TEST/foo" "$TEST/foo" )
    [ "$result" = "." ]
    assert "Relative path between same directories should be empty"
}


it_handles_parent_to_child()
{
    result=$( get_relative_path "$TEST" "$TEST/foo/bar" )
    [ "$result" = "foo/bar" ]
    assert "Should handle path from parent to child directory"
}


it_handles_child_to_parent()
{
    result=$( get_relative_path "$TEST/foo/bar" "$TEST" )
    [ "$result" = "../.." ]
    assert "Should handle path from child to parent directory"
}


it_handles_sibling_directories()
{
    result=$( get_relative_path "$TEST/foo" "$TEST/baz" )
    [ "$result" = "../baz" ]
    assert "Should handle path between sibling directories"
}


it_handles_file_source()
{
    result=$( get_relative_path "$TEST/foo/file.001.txt" "$TEST/baz" )
    [ "$result" = "../baz" ]
    assert "Should handle when source is a file"
}


it_handles_deep_paths()
{
    mkdir -p "$TEST/a/b/c/d"
    mkdir -p "$TEST/x/y/z"

    result=$( get_relative_path "$TEST/a/b/c/d" "$TEST/x/y/z" )
    [ "$result" = "../../../../x/y/z" ]
    assert "Should handle deep directory structures"
}


it_handles_absolute_paths()
{
    one=$( realpath "$TEST/foo" )
    two=$( realpath "$TEST/baz" )

    result=$( get_relative_path "$one" "$two" )
    [ "$result" = "../baz" ]
    assert "Should handle absolute paths correctly"
}


it_handles_non_existent_paths()
{
    result=$( get_relative_path "$TEST/none" "$TEST/foo" )
    [ $? -eq 0 ]
    assert "Should not fail with nonexistent source path"

    result=$( get_relative_path "$TEST/foo" "$TEST/none" )
    [ $? -eq 0 ]
    assert "Should not fail with nonexistent target path"
}


it_preserves_trailing_slashes()
{
    mkdir -p "$TEST/corge/"

    result=$( get_relative_path "$TEST/foo" "$TEST/corge/" )
    [ "$result" = "../corge" ]
    assert "Should handle trailing slashes correctly"
}
