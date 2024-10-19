source ./src/helpers.sh

# Example usage with debugging
source_dir="/Users/MHO/Work/Projects/Development/Web/Personal/flint/project"
package_dir="/Users/mho/Work/Projects/Development/Web/Personal/flint/package"

echo "Converting paths..."
hooks_path=$( get_relative_path "$source_dir" "$package_dir" )
wrapper_path=$( get_relative_path "$source_dir" "$package_dir/src" )

echo "Final paths:"
echo "Hooks path: $hooks_path"
echo "Wrapper path: $wrapper_path"
