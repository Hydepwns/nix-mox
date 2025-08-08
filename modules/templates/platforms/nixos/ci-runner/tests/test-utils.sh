#!/usr/bin/env bash
# Test utilities for CI runner tests

# Test job queue
testJobQueue() {
  local job="$1"
  local expected_result="$2"

  # Initialize queue
  queue_file="/tmp/test-queue"
  echo "$job" > "$queue_file"

  # Process job
  result=$(head -n 1 "$queue_file")
  if [ "$result" = "$expected_result" ]; then
    return 0
  else
    return 1
  fi
}

# Test logging
testLogging() {
  local level="$1"
  local message="$2"
  local expected_output="$3"

  logMessage() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
  }

  output=$(logMessage "$level" "$message")
  if [ "$output" = "$expected_output" ]; then
    return 0
  else
    return 1
  fi
}

# Test retry mechanism
testRetry() {
  local max_retries="$1"
  local retry_delay="$2"
  local operation="$3"
  local expected_result="$4"

  retries=0
  while [ $retries -lt "$max_retries" ]; do
    if eval "$operation"; then
      if [ "$expected_result" = "true" ]; then
        return 0
      else
        return 1
      fi
    fi
    retries=$((retries + 1))
    sleep "$retry_delay"
  done

  if [ "$expected_result" = "false" ]; then
    return 0
  else
    return 1
  fi
}

# Test parallel execution
testParallelExecution() {
  local max_parallel="$2"
  shift 2
  local jobs=("$@")

  active_jobs=0

  for job in "${jobs[@]}"; do
    if [ $active_jobs -lt "$max_parallel" ]; then
      active_jobs=$((active_jobs + 1))
      eval "$job" &
      job_pid=$!
      wait $job_pid
      active_jobs=$((active_jobs - 1))
    else
      wait -n
      active_jobs=$((active_jobs - 1))
      eval "$job" &
      job_pid=$!
      wait $job_pid
      active_jobs=$((active_jobs + 1))
    fi
  done

  return 0
}
