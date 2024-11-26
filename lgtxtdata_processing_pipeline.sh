#!/bin/bash

# Default configurations
split_lines=10000        # Default number of lines per split file
delimiter="|"            # Default delimiter for the input file
encoding="ISO-8859-1"    # Desired encoding - UTF-8 or ISO-8859-1
output_base_dir="./output" # Base output directory

# Usage function
usage() {
    echo "Usage: $0 <text_file> <sub_folder> [options]"
    echo "Options:"
    echo "  --lines=<number>       Number of lines per split file (default: $split_lines)"
    echo "  --delimiter=<char>     Delimiter for the input file (default: $delimiter)"
    echo "  --encoding=<encoding>  Encoding for the files, either UTF-8 or ISO-8859-1 (default: $encoding)"
    echo "Example:"
    echo "  $0 mydata.txt batch_2024 --lines=5000 --delimiter=|"
    exit 1
}

# Argument parsing
if [[ $# -lt 2 ]]; then
    usage
fi

text_file="$1"
sub_folder="$2"
shift 2

# Parse additional options
for arg in "$@"; do
    case $arg in
        --lines=*) split_lines="${arg#*=}" ;;
        --delimiter=*) delimiter="${arg#*=}" ;;
        --encoding=*) encoding="${arg#*=}" ;;
        *) echo "Unknown option: $arg"; usage ;;
    esac
done

# Validate input file
if [[ ! -f "$text_file" ]]; then
    echo "Error: File '$text_file' not found."
    exit 1
fi

# Track start time
start_time=$(date +%s)
start_datetime=$(date "+%d/%m/%Y %H:%M:%S")
echo "Script execution start time: ⏲️ [ $start_datetime ]"

# Prepare directories
split_dir="${output_base_dir}/split_files"
csv_dir="${output_base_dir}/converted_csv/${sub_folder}"
sql_dir="${output_base_dir}/sql_files/${sub_folder}"
mkdir -p "$split_dir" "$csv_dir" "$sql_dir"

# Clear the subfolders before processing
if [ -d "$split_dir" ]; then
    echo "Clearing text files in $split_dir..."
    rm -rf "$split_dir"/*
fi

if [ -d "$csv_dir" ]; then
    echo "Clearing csv files in $csv_dir..."
    rm -rf "$csv_dir"/*
fi

if [ -d "$sql_dir" ]; then
    echo "Clearing sql scripts in $sql_dir..."
    rm -rf "$sql_dir"/*
fi

# Derive prefix from the original file name
base_name=$(basename "$text_file" .txt)
split_prefix="${split_dir}/split_${base_name}"

# Step 1: Split the large text file
echo "Splitting file '$text_file' into chunks of $split_lines lines..."
split -l "$split_lines" -d --additional-suffix=.txt "$text_file" "$split_prefix"

# Step 2: Convert split files to CSV
echo "Converting split files to CSV in folder '$csv_dir'..."
for split_file in "$split_dir"/*.txt; do
    if [[ -f $split_file ]]; then
        split_base_name=$(basename "$split_file" .txt)
        output_csv="${csv_dir}/${split_base_name}.csv"
        
        echo "Converting $split_file to $output_csv..."
        iconv -f "$encoding" -t "$encoding" "$split_file" | sed "s/$delimiter/,/g" > "$output_csv"
    fi
done

# Step 3: Generate SQL scripts
table_name="${base_name}" # database table name must be the same as the file name
output_sql="${sql_dir}/${base_name}.sql"

# Count files for progress tracking
total_csv_files=$(find "$csv_dir" -name "*.csv" | wc -l)
file_count=0
processed_files=0

echo "Generating SQL scripts in '$output_sql'..."
echo "-- SQL script for inserting data into $table_name" > "$output_sql"
for csv_file in "$csv_dir"/*.csv; do
    if [[ -f $csv_file ]]; then
        file_count=$((file_count + 1))
	    processed_files=$((processed_files + 1))
        echo "Processing file $file_count of $total_csv_files: $csv_file"
        echo "-- Processing $csv_file..." >> "$output_sql"
        
        # Read and generate INSERT statements
        row_count=0
        tail -n +2 "$csv_file" | while IFS= read -r line; do
            row_count=$((row_count + 1))

            # Sanitize and format values
            values=$(echo "$line" | awk -v FS="," '{
                for (i=1; i<=NF; i++) {
                    gsub(/\047/, "");              # Remove single quotes
                    printf "\047%s\047%s", $i, (i==NF ? "" : ",")  # Wrap in single quotes
                }
            }')

            # Construct the INSERT statement
            echo "INSERT INTO [$table_name] VALUES ($values);" >> "$output_sql"

            # Output progress for every 1000 rows
            if (( row_count % 1000 == 0 )); then
                echo "  ✅ Processed $row_count rows in $csv_file"
            fi
        done
    fi
done

# Track end time and calculate elapsed time
end_time=$(date +%s)
end_datetime=$(date "+%d/%m/%Y %H:%M:%S")
elapsed_time=$((end_time - start_time))

# Display start, end times, and elapsed time
echo "Script execution end time: ⏲️ [ $end_datetime ]"
echo "Pipeline completed."
echo "  Split files in: $split_dir"
echo "  CSV files in: $csv_dir"
echo "  SQL script in: $output_sql"
echo "⏲️ Total execution time: $elapsed_time seconds."
