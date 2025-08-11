#!/usr/bin/env bash
# Summarize test failures from a Nushell test run.
# Usage: ./scripts/maintenance/ci/summarize-tests.sh

# Directory for storing test output
TMP_DIR="tmp"
# File to store raw test output
INPUT_FILE="$TMP_DIR/test_output.txt"
# File to store the summarized errors
OUTPUT_FILE="$TMP_DIR/test_error_summary.txt"
# Coverage directory for JSON test results
COVERAGE_DIR="coverage-tmp"

# Ensure tmp directory exists
mkdir -p "$TMP_DIR"

# Run the test suite and capture all output
echo "Running Nushell tests..."
if nu -c "source scripts/testing/run-tests.nu; run ['--unit']" > "$INPUT_FILE" 2>&1; then
  echo "All tests passed!" > "$OUTPUT_FILE"
  echo "Full summary in $OUTPUT_FILE"
  exit 0
fi

# If test failed
echo "Nushell tests failed. Full output in $INPUT_FILE" > "$OUTPUT_FILE" # Overwrite previous content

# Summarize warnings
echo "--- Warnings Summary ---" >> "$OUTPUT_FILE"
grep -E '\[warning\]|warning:|WARN' "$INPUT_FILE" >> "$OUTPUT_FILE" || echo "No warnings found." >> "$OUTPUT_FILE"

# Summarize test failures
echo "--- Test Failures Summary ---" >> "$OUTPUT_FILE"

# Pattern for Nushell test failures (✗ indicates failure)
failure_pattern='✗'

# Get line numbers of all failure indicators
failure_lines_with_numbers=$(grep -n "$failure_pattern" "$INPUT_FILE")

if [ -z "$failure_lines_with_numbers" ]; then
  {
    echo "No test failures found in the output."
    echo "This might be a different type of test suite failure."
    echo "Please check the full output in $INPUT_FILE."
  } >> "$OUTPUT_FILE"
else
  # Get the line number of the last line to mark the end of test details
  last_line_num=$(wc -l < "$INPUT_FILE")

  declare -a start_lines
  declare -a failure_messages
  while IFS= read -r entry; do
    start_lines+=("$(echo "$entry" | cut -d: -f1)")
    failure_messages+=("$(echo "$entry" | cut -d: -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')") # Store message, trim whitespace
  done <<< "$failure_lines_with_numbers"

  for i in "${!start_lines[@]}"; do
    current_start_line=${start_lines[$i]}
    current_message=${failure_messages[$i]}

    echo "$current_message" >> "$OUTPUT_FILE" # Output the failure message

    # Determine the start and end lines for this failure's context block
    # Block starts from the line *after* the current failure's line
    block_content_start_line=$((current_start_line + 1))
    block_content_end_line=""

    if [ "$i" -lt $((${#start_lines[@]} - 1)) ]; then
      # Block ends just before the next failure's line
      next_failure_start_line=${start_lines[$((i + 1))]}
      block_content_end_line=$((next_failure_start_line - 1))
    else
      # For the last failure, block ends at the last line
      block_content_end_line=$last_line_num
    fi

    # Ensure the calculated block end line is not before its start line
    if [ "$block_content_end_line" -lt "$block_content_start_line" ]; then
      {
        echo "    (No further context extracted or context ends immediately after failure)"
        echo ""
      } >> "$OUTPUT_FILE"
    else
      # Extract the whole context block for this specific failure
      failure_context_block=$(sed -n "${block_content_start_line},${block_content_end_line}p" "$INPUT_FILE")

      if [ -n "$failure_context_block" ]; then
        # Print the first 3 lines of the failure context block
        # This often captures: test name, error details, and first detail line
        echo "$failure_context_block" | head -n 3 >> "$OUTPUT_FILE"

        # Then, grep the rest of the block (from the 4th line onwards) for more specific details
        num_block_lines=$(echo "$failure_context_block" | wc -l | xargs) # xargs to trim whitespace from wc -l output
        if [ "$num_block_lines" -gt 3 ]; then
          echo "$failure_context_block" | tail -n +4 |
            grep -E '^\s*\*\*|\(test/|\scode:|\sleft:|\sright:|expected|got|Assertion with|stacktrace:|Error:|ERROR:' >> "$OUTPUT_FILE"
        fi
      else
        {
          echo "    (No context block found between this failure and the next/end)"
          echo ""
        } >> "$OUTPUT_FILE"
      fi
    fi
  done
fi

# Add JSON test results summary if available
if [ -d "$COVERAGE_DIR" ]; then
  echo "--- JSON Test Results Summary ---" >> "$OUTPUT_FILE"

  # Find all JSON result files
  result_files=$(find "$COVERAGE_DIR" -name "test_result_*.json" 2> /dev/null)

  if [ -n "$result_files" ]; then
    echo "Found $(echo "$result_files" | wc -l) test result files:" >> "$OUTPUT_FILE"

    # Count passed/failed tests
    passed_count=0
    failed_count=0
    skipped_count=0

    while IFS= read -r file; do
      if [ -f "$file" ]; then
        # Extract status from JSON (simple grep approach)
        status=$(grep -o '"status":"[^"]*"' "$file" | cut -d'"' -f4)
        test_name=$(grep -o '"name":"[^"]*"' "$file" | cut -d'"' -f4)

        case "$status" in
          "passed")
            passed_count=$((passed_count + 1))
            ;;
          "failed")
            failed_count=$((failed_count + 1))
            echo "  FAILED: $test_name" >> "$OUTPUT_FILE"
            ;;
          "skipped")
            skipped_count=$((skipped_count + 1))
            ;;
        esac
      fi
    done <<< "$result_files"

    echo "" >> "$OUTPUT_FILE"
    {
      echo "Test Summary:"
      echo "  Passed: $passed_count"
      echo "  Failed: $failed_count"
      echo "  Skipped: $skipped_count"
      total=$((passed_count + failed_count + skipped_count))
      if [ $total -gt 0 ]; then
        pass_rate=$((passed_count * 100 / total))
        echo "  Pass Rate: ${pass_rate}%"
      fi
    } >> "$OUTPUT_FILE"
  else
    echo "No test result files found in $COVERAGE_DIR" >> "$OUTPUT_FILE"
  fi
else
  echo "Coverage directory $COVERAGE_DIR not found" >> "$OUTPUT_FILE"
fi

echo "Full summary in $OUTPUT_FILE"
