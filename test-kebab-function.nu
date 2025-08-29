#!/usr/bin/env nu

# Test file with kebab-case function to test pre-commit hook
def test_kebab_function [] {
    print "This is a test function with kebab-case naming"
}

def main [] {
    test_kebab_function
}