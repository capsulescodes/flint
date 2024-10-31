get_absolute_path()
{
    local path="$1"

    if [ -f "$path" ]

    then
        local dir="$( cd "$( dirname "$path" )" && pwd )"

        echo "${dir}/$( basename "$path" )"
    else
        ( cd "$path" 2>/dev/null && pwd ) || echo "$path"
    fi
}


get_relative_path()
{
    local source="$1"
    local target="$2"

    source="$( get_absolute_path "$source" )"
    target="$( get_absolute_path "$target" )"

    if [ -f "$source" ]

    then
        source=$( dirname "$source" )
    fi

    source="${source%/}"
    target="${target%/}"

    if [ "$source" = "$target" ]

    then
        echo ""

        return
    fi

    IFS='/' read -ra source_parts <<< "${source#/}"
    IFS='/' read -ra target_parts <<< "${target#/}"

    local common_length=0

    for (( i=0; i < ${#source_parts[@]} && i < ${#target_parts[@]}; i++ ))

    do
        if [ "${source_parts[i]}" = "${target_parts[i]}" ]

        then
            (( common_length++ ))
        else
            break
        fi
    done

   if [ $common_length -eq 0 ]

   then
        echo "$target"

        return
    fi


    local result=""

    for (( i=common_length; i < ${#source_parts[@]}; i++ ))
    do
        result+="../"
    done

    for (( i=common_length; i < ${#target_parts[@]}; i++ ))

    do
        result+="${target_parts[i]}"

        if [ $i -lt $(( ${#target_parts[@]} - 1 )) ]

        then
            result+="/"
        fi
    done

    echo "$result"
}
