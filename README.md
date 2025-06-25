# Large Text File (LTF) Processing Pipeline Script

This script automates the process of handling large pipe-delimited text files. It splits the input file into smaller chunks, converts the chunks into CSV format, and generates SQL scripts for database insertion.

## Features

1. **Splitting Large Files**:
   - Splits the input text file into smaller files with a configurable number of lines.
2. **CSV Conversion**:
   - Converts split files from pipe-delimited format to CSV with proper encoding and delimiter replacement. PS: Specify `--delimiter=,` argument if the file you are working with is comma-delimited.
3. **SQL Script Generation**:
   - Creates SQL `INSERT` statements for a buffer range of 1000 by combining each CSV row insert values into a single statement per 1000 csv file iterations whilst ensuring proper formatting.
4. **Customizable Options**:
   - Allows you to specify sub-folder names, delimiters, encoding, and number of lines per split if they are different from the scripts default configuration.

## Requirements

- **Bash** (Linux or WSL on Windows)
- Tools:
  - `split` (for file splitting)
  - `sed` (for delimiter replacement)
  - `iconv` (for encoding conversion)
  - `awk` (for SQL formatting)

## Usage

(Optional) You can opt to create an "input" folder and add the raw text file(s) in it instead of placing the files in the project root. On the command below, you may use the relative path (./input/<text_file>) if you choose do do so.

### Basic Command

```bash
./lgtxtdata_processing_pipeline.sh <text_file> <sub_folder> [options]
```

### Options

- `--lines=<number>`: Number of lines per split file (default: `10000`).
- `--delimiter=<char>`: Delimiter in the input file (default: `|`).
- `--encoding=<encoding>`: Desired file encoding (default: `UTF-8`).

### Examples

#### Basic Usage

```bash
./lgtxtdata_processing_pipeline.sh large_file.txt batch_2024
```

- **Input File**: `large_file.txt`
- **CSV Sub-folder**: `batch_2024`

#### Custom Options

```bash
./lgtxtdata_processing_pipeline.sh large_file.txt batch_2024 --lines=5000 --delimiter="|" --encoding="ISO-8859-1"
```

## Output Structure

The script organizes outputs into the following directories under `./output`:

1. **Split Files**: `./output/split_files/`
2. **CSV Files**: `./output/converted_csv/<sub_folder>/`
3. **SQL Script**: `./output/sql_files/<input_file_name>.sql`

### Example File Tree

```plaintext
output/
├── split_files/
│   ├── split_large_file_00.txt
│   ├── split_large_file_01.txt
│   └── ...
├── converted_csv/
│   └── batch_2024/
│       ├── split_large_file_00.csv
│       ├── split_large_file_01.csv
│       └── ...
└── sql_files/
    └── large_file.sql
```

## Generated SQL Format

Each row in the CSV is converted into an SQL `INSERT` statement (example):

```sql
INSERT INTO [Outpatient_Visit_Data] VALUES ('00000000','78530000','NYATHI THUSILE','EYEG','ST JOHNS RETINAL CLINIC','13/06/2022 10:54:50');
```

## Error Handling

- Validates the existence of the input file.
- Ensures all output directories are created before processing.
- Handles single quotes in data by removing them.

## Execution Time

The script displays:

- **Start Time**: When execution begins.
- **End Time**: When processing finishes.
- **Elapsed Time**: Total duration of execution.

## Contribution

Feel free to fork and contribute improvements to this script.
