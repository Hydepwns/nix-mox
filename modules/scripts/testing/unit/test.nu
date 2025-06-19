# Test module for nix-mox
use std assert

# Test basic functionality
def test_basic [] {
    print "Testing basic functionality..."
    
    # Test that we can run a simple command
    let result = (echo "test" | str trim)
    assert ($result == "test") "Basic echo test failed"
    
    # Test that we can use basic Nushell functions
    let numbers = [1, 2, 3, 4, 5]
    let sum = ($numbers | math sum)
    assert ($sum == 15) "Math sum test failed"
    
    # Test string operations
    let text = "hello world"
    let upper = ($text | str upcase)
    assert ($upper == "HELLO WORLD") "String upcase test failed"
}

# Test file operations
def test_file_ops [] {
    print "Testing file operations..."
    
    # Test that we can create and read a temporary file
    let temp_file = (mktemp)
    "test content" | save --force $temp_file
    
    let content = (open $temp_file | str trim)
    assert ($content == "test content") "File read/write test failed"
    
    # Clean up
    rm $temp_file
}

# Test environment variables
def test_env [] {
    print "Testing environment variables..."
    
    # Test that we can set and read environment variables
    $env.TEST_VAR = "test_value"
    assert ($env.TEST_VAR == "test_value") "Environment variable test failed"
    
    # Clean up
    hide-env TEST_VAR
}

# Test data structures
def test_data_structures [] {
    print "Testing data structures..."
    
    # Test lists
    let list = [1, 2, 3]
    assert (($list | length) == 3) "List length test failed"
    
    # Test records
    let record = { name: "test", value: 42 }
    assert ($record.name == "test") "Record access test failed"
    assert ($record.value == 42) "Record value test failed"
    
    # Test tables
    let table = [[name, value]; [a, 1], [b, 2]]
    assert (($table | length) == 2) "Table length test failed"
}

# Main test runner
def main [] {
    print "Starting basic functionality tests..."
    
    # Run all tests
    test_basic
    test_file_ops
    test_env
    test_data_structures
    
    print "All basic tests passed!"
}

# Run tests if this file is executed directly
if ($env.NU_TEST? == "true") {
    main
} else {
    main
}
