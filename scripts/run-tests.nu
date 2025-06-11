#!/usr/bin/env nu

# Set up test environment
$env.NU_TEST = "true"

# Run the test module
source ../tests/run-tests.nu
main