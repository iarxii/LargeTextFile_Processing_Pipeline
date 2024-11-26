#!/bin/bash

# Variables
input_dir="./converted_csv"  # Directory containing the converted CSV files
output_sql="mssql_server_outpatient_visit_data.sql"      # Final SQL script file
database_name="chbah_medicom_archive_db"   # Database name
table_name="Outpatient_Visit_Data"         # Table name
delimiter=","                # CSV delimiter (comma)

# Track start time
start_time=$(date +%s)
start_datetime=$(date "+%d/%m/%Y %H:%M:%S")
echo "Script execution start time: ⏲️[ $start_datetime ]"

# Initialize SQL script
echo "Initializing SQL script..." 
echo "-- SQL Script to Create Database and Insert Data" > "$output_sql"
echo "IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = '$database_name')" >> "$output_sql"
echo "BEGIN" >> "$output_sql"
echo "    CREATE DATABASE [$database_name];" >> "$output_sql"
echo "END;" >> "$output_sql"
echo "GO" >> "$output_sql"
echo "USE [$database_name];" >> "$output_sql"

# Extract header from the first CSV file to create the table structure
echo "Extracting table structure from the first CSV file..."
first_file=$(find "$input_dir" -name "*.csv" | head -n 1)
if [[ -z "$first_file" ]]; then
    echo "No CSV files found in $input_dir. Exiting."
    exit 1
fi

header=$(head -n 1 "$first_file")
columns=()
for col in $(echo "$header" | tr "$delimiter" "\n"); do
    sanitized_col=$(echo "$col" | sed 's/[^a-zA-Z0-9_]/_/g')  # Sanitize column names
    columns+=("[$sanitized_col] NVARCHAR(MAX)")
done

echo "Creating table structure in SQL script..."
echo "IF OBJECT_ID('$table_name', 'U') IS NOT NULL DROP TABLE [$table_name];" >> "$output_sql"
echo "CREATE TABLE [$table_name] (" >> "$output_sql"
echo "    $(IFS=,; echo "${columns[*]}")" >> "$output_sql"
echo ");" >> "$output_sql"
echo "GO" >> "$output_sql"

# Count files for progress tracking
total_files=$(find "$input_dir" -name "*.csv" | wc -l)
file_count=0
processed_files=0

# Process each CSV file and generate INSERT statements
echo "Processing CSV files and generating INSERT statements..."
for file in "$input_dir"/*.csv; do
    if [[ -f $file ]]; then
        file_count=$((file_count + 1))
	processed_files=$((processed_files + 1))
        echo "Processing file $file_count of $total_files: $file"
        echo "-- Processing $file" >> "$output_sql"

        # Read and generate INSERT statements
        row_count=0
        tail -n +2 "$file" | while IFS= read -r line; do
            row_count=$((row_count + 1))

	        # Sanitize and format values
            values=$(echo "$line" | awk -v FS="$delimiter" '{
                for (i=1; i<=NF; i++) {
                    gsub(/\047/, "");              # Remove single quotes within the value
                    printf "\047%s\047%s", $i, (i==NF ? "" : ",")  # Wrap each value in single quotes
                }
            }')

            # Construct the INSERT statement
            echo "INSERT INTO [$table_name] VALUES ($values);" >> "$output_sql"
	
            # Escape single quotes in the data # deprecate this code block
            # escaped_line=$(echo "$line" | sed "s/'/''/g")
            # values=$(echo "$escaped_line" | awk -v OFS="','" -v FS="$delimiter" '{print "'"'"'" $0 "'"'"'"}')
            # echo "INSERT INTO [$table_name] VALUES ($values);" >> "$output_sql"

            # Output progress for every 1000 rows
            if (( row_count % 1000 == 0 )); then
                echo "  Processed $row_count rows in $file"
            fi
        done
    fi
done

# Total files processed
echo "Total files processed: $processed_files of $total_files"

# Finalize script
echo "Finalizing SQL script..."
echo "GO" >> "$output_sql"

echo "SQL script generated: $output_sql"

# Track end time and calculate elapsed time
end_time=$(date +%s)
end_datetime=$(date "+%d/%m/%Y %H:%M:%S")
elapsed_time=$((end_time - start_time))

# Display start, end times, and elapsed time
echo "Script execution end time: ⏲️ [ $end_datetime ]"
echo "Script execution completed in $elapsed_time seconds. ⏲️"