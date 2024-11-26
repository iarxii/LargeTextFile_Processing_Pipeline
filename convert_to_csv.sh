#!/bin/bash

# Variables
input_dir="./"  # Directory containing the split files
output_dir="./converted_csv"  # Directory for converted CSV files
encoding="UTF-8"  # Desired encoding (e.g., UTF-8 or ISO-8859-1)

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Process each split file
for file in "${input_dir}"split_*; do
    if [[ -f $file ]]; then
        # Extract base name and set output CSV file name
        base_name=$(basename "$file")
        output_file="${output_dir}/${base_name%.txt}.csv"

        # Replace "|" with "," and convert encoding
        iconv -f "$encoding" -t "$encoding" "$file" | sed 's/|/,/g' > "$output_file"

        echo "Converted: $file -> $output_file"
    fi
done

echo "All files have been processed and saved to $output_dir."
