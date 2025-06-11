# Load test utilities
source ./test-utils.nu

# Test assert_equal
def test_assert_equal [] {
    print "Testing assert_equal..."
    
    # Test successful assertion
    assert_equal 1 1 "Numbers should be equal"
    print "✓ Basic assertion passed"
    
    # Test string comparison
    assert_equal "hello" "hello" "Strings should be equal"
    print "✓ String comparison passed"
    
    # Test array comparison
    assert_equal [1 2 3] [1 2 3] "Arrays should be equal"
    print "✓ Array comparison passed"
}

# Test test_retry
def test_retry_mechanism [] {
    print "Testing test_retry..."
    
    # Test successful retry
    test_retry 3 1 { true } true
    print "✓ Successful retry passed"
    
    # Test failed retry
    test_retry 2 1 { false } false
    print "✓ Failed retry passed"
}

# Test test_logging
def test_logging_function [] {
    print "Testing test_logging..."
    
    test_logging "INFO" "Test message" "[INFO] Test message"
    print "✓ Logging test passed"
}

# Run all tests
def main [] {
    print "Starting test utilities verification..."
    print "----------------------------------------"
    
    test_assert_equal
    print "----------------------------------------"
    test_retry_mechanism
    print "----------------------------------------"
    test_logging_function
    print "----------------------------------------"
    
    print "All tests completed successfully!"
}

# Run the tests
main 