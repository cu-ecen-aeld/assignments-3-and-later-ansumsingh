#!/bin/bash


if [ "$#" -ne 2 ]; then
    echo "Error: Both a directory and a search string must be specified."
    exit 1
fi

#Assign arguments to variables
filesdir=$1
searchstr=$2

# Check if filesdir is a valid directory
if [ ! -d "$filesdir" ]; then
    echo "Error: $filesdir is not a valid directory."
    exit 1
fi

# Count the number of files in the directory (including subdirectories)
num_files=$(find "$filesdir" -type f| wc -l)

# Count the number of lines containing the search string
num_matching_lines=$(grep -r "$searchstr" "$filesdir" 2>/dev/null | wc -l)

# Print the result
echo "The number of files are $num_files and the number of matching lines are $num_matching_lines"
