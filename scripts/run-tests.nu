#!/usr/bin/env nu

# Set up test environment
$env.NU_TEST = "true"

# Run the test module
source scripts/tests/test.nu
main 