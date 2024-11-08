beforeAll()
{
    path=$PWD

    source "$path/src/helpers.sh"

    TEST=$( mktemp -d )

    cd $TEST > /dev/null || exit 1

    mkdir -p foo/bar
    mkdir -p baz/qux

    touch foo/file.001.txt
    touch baz/file.002.txt
}

afterAll()
{
    cd $path > /dev/null || exit 1

    rm -rf "$TEST"
}




it_handles_file_paths()
{
    touch "$TEST/file.txt"

    result=$( get_absolute_path "$TEST/file.txt" )
    [ $result = "$TEST/file.txt" ]
    assert "Should return absolute path for a file"
}


it_handles_directory_paths()
{
    mkdir -p "$TEST/foo"

    result=$( get_absolute_path "$TEST/foo" )
    [ $result = "$TEST/foo" ]
    assert "Should return absolute path for a directory"
}


it_handles_nested_paths()
{
    mkdir -p "$TEST/foo/bar"
    touch "$TEST/foo/bar/file.txt"

    result=$( get_absolute_path "$TEST/foo/bar/file.txt" )
    [ $result = "$TEST/foo/bar/file.txt" ]
    assert "Should return absolute path for nested file"
}


it_handles_relative_paths()
{
    result=$( get_absolute_path "./foo" )
    [ $result = "$TEST/foo" ]
    assert "Should convert relative path to absolute path"
}


it_handles_parent_directory_paths()
{
    cd "$TEST/foo/bar"

    result=$( get_absolute_path "../" )
    [ $result = "$TEST/foo" ]
    assert "Should handle parent directory references"
}


it_handles_non_existent_paths()
{
    result=$( get_absolute_path "$TEST/none" )
    [ $result = "$TEST/none" ]
    assert "Should return original path for non-existent paths"
}


it_handles_empty_path()
{
    result=$( get_absolute_path "" )
    [ $result = "$( pwd )" ]
    assert "Should return current directory for empty path"
}


it_handles_current_directory()
{
    result=$( get_absolute_path "." )
    [ $result = "$( pwd )" ]
    assert "Should handle current directory path"
}


it_preserves_trailing_slashes_in_absolute_path()
{
    mkdir -p "$TEST/foo"

    result=$( get_absolute_path "$TEST/foo/" )
    [ $result = "$TEST/foo" ]
    assert "Should handle paths with trailing slashes"
}


it_handles_same_directory()
{
    result=$( get_relative_path "$TEST/foo" "$TEST/foo" )
    [ -z $result ]
    assert "Relative path between same directories should be empty"
}


it_handles_parent_to_child()
{
    result=$( get_relative_path "$TEST" "$TEST/foo/bar" )
    [ $result = "foo/bar" ]
    assert "Should handle path from parent to child directory"
}


it_handles_child_to_parent()
{
    result=$( get_relative_path "$TEST/foo/bar" "$TEST" )
    [ $result = "../../" ]
    assert "Should handle path from child to parent directory"
}


it_handles_sibling_directories()
{
    result=$( get_relative_path "$TEST/foo" "$TEST/baz" )
    [ $result = "../baz" ]
    assert "Should handle path between sibling directories"
}


it_handles_file_source()
{
    result=$( get_relative_path "$TEST/foo/file.001.txt" "$TEST/baz" )
    [ $result = "../baz" ]
    assert "Should handle when source is a file"
}


it_handles_deep_paths()
{
    mkdir -p "$TEST/a/b/c/d"
    mkdir -p "$TEST/x/y/z"

    result=$( get_relative_path "$TEST/a/b/c/d" "$TEST/x/y/z" )
    [ $result = "../../../../x/y/z" ]
    assert "Should handle deep directory structures"
}


it_handles_absolute_paths()
{
    result=$( get_relative_path "$TEST/foo" "$TEST/baz" )
    [ $result = "../baz" ]
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


it_preserves_trailing_slashes_in_relative_path()
{
    mkdir -p "$TEST/corge/"

    result=$( get_relative_path "$TEST/foo" "$TEST/corge/" )
    [ $result = "../corge" ]
    assert "Should handle trailing slashes correctly"
}


it_handles_no_common_path()
{
    result=$( get_relative_path "/usr/local/bin" "$TEST/foo/bar" )
    [ $result = "$TEST/foo/bar" ]
    assert "Should return the target's absolute path when no common parts exist"
}
