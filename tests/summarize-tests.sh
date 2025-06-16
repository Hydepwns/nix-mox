#!/bin/bash
# Summarize test failures from a BATS test run.
# Usage: ./tests/summarize-tests.sh

# Directory for storing test output
TMP_DIR="tmp"
# File to store raw test output
INPUT_FILE="$TMP_DIR/test_output.txt"
# File to store the summarized errors
OUTPUT_FILE="$TMP_DIR/test_error_summary.txt"

# Ensure tmp directory exists
mkdir -p "$TMP_DIR"

# Run the test suite and capture all output
echo "Running BATS tests..."
if bats tests/ > "$INPUT_FILE" 2>&1; then
  echo "All tests passed!" > "$OUTPUT_FILE"
  echo "Full summary in $OUTPUT_FILE"
  exit 0
fi

# If bats test failed
echo "BATS tests failed. Full output in $INPUT_FILE" > "$OUTPUT_FILE" # Overwrite previous content

# Summarize warnings
echo "--- Warnings Summary ---" >> "$OUTPUT_FILE"
grep -E '\[warning\]|warning:' "$INPUT_FILE" >> "$OUTPUT_FILE" || echo "No warnings found." >> "$OUTPUT_FILE"

# Summarize test failures
echo "--- Test Failures Summary ---" >> "$OUTPUT_FILE"

# Pattern for BATS test failures
failure_pattern='^not ok [0-9]+'

# Get line numbers of all failure headers
failure_headers_with_lines=$(grep -nE "$failure_pattern" "$INPUT_FILE")

if [ -z "$failure_headers_with_lines" ]; then
  echo "No numbered test failures found in the output." >> "$OUTPUT_FILE"
  echo "This might be a different type of test suite failure." >> "$OUTPUT_FILE"
  echo "Please check the full output in $INPUT_FILE." >> "$OUTPUT_FILE"
else
  # Get the line number of the last line to mark the end of test details
  last_line_num=$(wc -l < "$INPUT_FILE")

  declare -a start_lines
  declare -a headers
  while IFS= read -r entry; do
    start_lines+=("$(echo "$entry" | cut -d: -f1)")
    headers+=("$(echo "$entry" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')") # Store header, trim whitespace
  done <<< "$failure_headers_with_lines"

  for i in "${!start_lines[@]}"; do
    current_start_line=${start_lines[$i]}
    current_header=${headers[$i]}

    echo "$current_header" >> "$OUTPUT_FILE" # Output the test header

    # Determine the start and end lines for this failure's context block
    # Block starts from the line *after* the current failure's header
    block_content_start_line=$((current_start_line + 1))
    block_content_end_line=""

    if [ "$i" -lt $((${#start_lines[@]} - 1)) ]; then
      # Block ends just before the next failure's header
      next_failure_header_start_line=${start_lines[$((i+1))]}
      block_content_end_line=$((next_failure_header_start_line - 1))
    else
      # For the last failure, block ends at the last line
      block_content_end_line=$last_line_num
    fi

    # Ensure the calculated block end line is not before its start line
    if [ "$block_content_end_line" -lt "$block_content_start_line" ]; then
      echo "    (No further context extracted or context ends immediately after header)" >> "$OUTPUT_FILE"
    else
      # Extract the whole context block for this specific failure
      failure_context_block=$(sed -n "${block_content_start_line},${block_content_end_line}p" "$INPUT_FILE")

      if [ -n "$failure_context_block" ]; then
        # Print the first 3 lines of the failure context block
        # This often captures: test name, error type/message, and first detail line
        echo "$failure_context_block" | head -n 3 >> "$OUTPUT_FILE"

        # Then, grep the rest of the block (from the 4th line onwards) for more specific details
        num_block_lines=$(echo "$failure_context_block" | wc -l | xargs) # xargs to trim whitespace from wc -l output
        if [ "$num_block_lines" -gt 3 ]; then
            echo "$failure_context_block" | tail -n +4 | \
            grep -E '^\s*\*\*|\(test/|\scode:|\sleft:|\sright:|expected|got|Assertion with|stacktrace:' >> "$OUTPUT_FILE"
        fi
      else
        echo "    (No context block found between this failure and the next/end)" >> "$OUTPUT_FILE"
      fi
    fi
    echo "" >> "$OUTPUT_FILE" # Add a blank line for readability before the next failure summary
  done
fi

echo "Full summary in $OUTPUT_FILE"
