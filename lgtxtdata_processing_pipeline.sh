#!/bin/bash

# Default configurations
split_lines=10000        # Default number of lines per split file
delimiter="|"            # Default delimiter for the input file
encoding="UTF-8"         # Desired encoding
output_base_dir="./output" # Base output directory

# Usage function
usage() {
    echo "Usage: $0 <text_file> <sub_folder> [options]"
    echo "Options:"
    echo "  --lines=<number>       Number of lines per split file (default: $split_lines)"
    echo "  --delimiter=<char>     Delimiter for the input file (default: $delimiter)"
    echo "  --encoding=<encoding>  Encoding for the files (default: $encoding)"
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

# Prepare directories
split_dir="${output_base_dir}/split_files"
csv_dir="${output_base_dir}/converted_csv/${sub_folder}"
sql_dir="${output_base_dir}/sql_files"
mkdir -p "$split_dir" "$csv_dir" "$sql_dir"

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
table_name="Outpatient_Visit_Data"
output_sql="${sql_dir}/${base_name}.sql"

echo "Generating SQL scripts in '$output_sql'..."
echo "-- SQL script for inserting data into $table_name" > "$output_sql"
for csv_file in "$csv_dir"/*.csv; do
    if [[ -f $csv_file ]]; then
        echo "-- Processing $csv_file..." >> "$output_sql"
        
        tail -n +2 "$csv_file" | while IFS= read -r line; do
            values=$(echo "$line" | awk -v FS="," '{
                for (i=1; i<=NF; i++) {
                    gsub(/\047/, "");              # Remove single quotes
                    printf "\047%s\047%s", $i, (i==NF ? "" : ",")  # Wrap in single quotes
                }
            }')
            echo "INSERT INTO [$table_name] VALUES ($values);" >> "$output_sql"
        done
    fi
done

# Completion message with timing
start_time=$(date +%s)
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo "Pipeline completed."
echo "  Split files in: $split_dir"
echo "  CSV files in: $csv_dir"
echo "  SQL script in: $output_sql"
echo "Total execution time: $elapsed_time seconds."
