beforeAll()
{
    TEST=$( mktemp -d )


    mkdir "$TEST/.core"

    cp "$PWD/src/helpers.sh" "$TEST/.core/helpers.sh"

    source "$TEST/.core/helpers.sh"
}

afterAll()
{
    [[ -n "$TEST" && -d "$TEST" ]] && rm -r $TEST
}




it_handles_file_paths()
{
    output=$( get_absolute_path "$TEST/file.foo" )
    [[ $output = "$TEST/file.foo" ]]
    assert "Should return absolute path for a file"
}


it_handles_directory_paths()
{
    mkdir -p "$TEST/foo"

    output=$( get_absolute_path "$TEST/foo" )
    [[ $output = "$TEST/foo" ]]
    assert "Should return absolute path for a directory"
}


it_handles_nested_paths()
{
    mkdir -p "$TEST/foo/bar"
    touch "$TEST/foo/bar/file.txt"

    output=$( get_absolute_path "$TEST/foo/bar/file.foo" )
    [[ $output = "$TEST/foo/bar/file.foo" ]]
    assert "Should return absolute path for nested file"
}


it_handles_relative_paths()
{
    pwd=$PWD

    cd $TEST

    output=$( get_absolute_path "./foo" )
    [[ $output = "$TEST/foo" ]]
    assert "Should convert relative path to absolute path"

    cd $pwd
}


it_handles_parent_directory_paths()
{
    pwd=$PWD

    mkdir -p "$TEST/foo/bar"

    cd "$TEST/foo/bar"

    output=$( get_absolute_path "../" )
    [[ $output = "$TEST/foo" ]]
    assert "Should handle parent directory references"

    rm -r "$TEST/foo"

    cd $pwd
}


it_handles_non_existent_absolute_paths()
{
    output=$( get_absolute_path "$TEST/none" )
    [[ $output = "$TEST/none" ]]
    assert "Should return original path for non-existent paths"
}


it_handles_empty_path()
{
    output=$( get_absolute_path "" )
    [[ $output = "$( pwd )" ]]
    assert "Should return current directory for empty path"
}


it_handles_current_directory()
{
    output=$( get_absolute_path "." )
    [[ $output = "$( pwd )" ]]
    assert "Should handle current directory path"
}


it_preserves_trailing_slashes_in_absolute_path()
{
    mkdir -p "$TEST/foo"

    output=$( get_absolute_path "$TEST/foo/" )
    [[ $output = "$TEST/foo" ]]
    assert "Should handle paths with trailing slashes"
}


it_handles_same_directory()
{
    output=$( get_relative_path "$TEST/foo" "$TEST/foo" )
    [[ $output = "." ]]
    assert "Relative path between same directories should be empty"
}


it_handles_parent_to_child()
{
    output=$( get_relative_path "$TEST" "$TEST/foo/bar" )
    [[ $output = "foo/bar" ]]
    assert "Should handle path from parent to child directory"
}


it_handles_child_to_parent()
{
    output=$( get_relative_path "$TEST/foo/bar" "$TEST" )
    [[ $output = "../../" ]]
    assert "Should handle path from child to parent directory"
}


it_handles_sibling_directories()
{
    output=$( get_relative_path "$TEST/foo" "$TEST/baz" )
    [[ $output = "../baz" ]]
    assert "Should handle path between sibling directories"
}


it_handles_file_source()
{
    output=$( get_relative_path "$TEST/foo/file.001.txt" "$TEST/baz" )
    [[ $output = "../../baz" ]]
    assert "Should handle when source is a file"
}


it_handles_deep_paths()
{
    mkdir -p "$TEST/a/b/c/d"
    mkdir -p "$TEST/x/y/z"

    output=$( get_relative_path "$TEST/a/b/c/d" "$TEST/x/y/z" )
    [[ $output = "../../../../x/y/z" ]]
    assert "Should handle deep directory structures"

    rm -r "$TEST/a/b/c/d"
    rm -r "$TEST/x/y/z"
}


it_handles_absolute_paths()
{
    output=$( get_relative_path "$TEST/foo" "$TEST/baz" )
    [[ $output = "../baz" ]]
    assert "Should handle absolute paths correctly"
}


it_handles_non_existent_relative_paths()
{
    output=$( get_relative_path "$TEST/none" "$TEST/foo" )
    [[ $? -eq 0 ]]
    assert "Should not fail with nonexistent source path"

    output=$( get_relative_path "$TEST/foo" "$TEST/none" )
    [[ $? -eq 0 ]]
    assert "Should not fail with nonexistent target path"
}


it_preserves_trailing_slashes_in_relative_path()
{
    mkdir -p "$TEST/corge/"

    output=$( get_relative_path "$TEST/foo" "$TEST/corge/" )
    [[ $output = "../corge" ]]
    assert "Should handle trailing slashes correctly"
}


it_handles_no_common_path()
{
    output=$( get_relative_path "/usr/local/bin" "$TEST/foo/bar" )
    [[ $output = "../../..$TEST/foo/bar" ]]
    assert "Should return the target's absolute path when no common parts exist"
}
