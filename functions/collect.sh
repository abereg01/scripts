#!/bin/bash

read -p "Enter folder path: " folder_path

if [ ! -d "$folder_path" ]; then
    echo "Directory does not exist"
    exit 1
fi

if [ "$folder_path" = "." ]; then
    folder_name=$(basename "$(pwd)")
    folder_path="$(pwd)"
else
    folder_name=$(basename "$folder_path")
fi

output_file="$HOME/${folder_name}_collection.txt"

{
    echo "Directory structure:"
    find "$folder_path" -type d
    echo -e "\nFile contents:"
    find "$folder_path" -type f -exec sh -c '
        echo "=== $1 ==="
        cat "$1"
        echo
    ' sh {} \;
} > "$output_file"

echo "Files collected in $output_file"
