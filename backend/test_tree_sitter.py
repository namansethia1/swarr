#!/usr/bin/env python3
"""Test script for tree-sitter functionality"""

from code_analyzer import analyze_code_with_tree_sitter

def test_javascript_with_error():
    """Test JavaScript code with syntax error"""
    code = """function factorial(n) {
  if (n === 0) {
    return 1;
  } else {
    for (let i = 1; i <= n; i++ {  // Missing closing parenthesis
      console.log(i);
    }
    return n;
  }
}"""
    
    print("Testing JavaScript code with syntax error:")
    print("=" * 50)
    results = list(analyze_code_with_tree_sitter(code, 'javascript'))
    print(f"Found {len(results)} analysis results:")
    
    for result in results[:15]:  # Show first 15 results
        error_indicator = "❌" if result['isError'] else "✅"
        print(f"{error_indicator} Line {result['startLine']}: {result['type']}")
        if result['isError']:
            print(f"   Error: {result['message']}")

def test_valid_javascript():
    """Test valid JavaScript code"""
    code = """function factorial(n) {
  if (n === 0) {
    return 1;
  } else {
    for (let i = 1; i <= n; i++) {
      console.log(i);
    }
    return n;
  }
}"""
    
    print("\nTesting valid JavaScript code:")
    print("=" * 50)
    results = list(analyze_code_with_tree_sitter(code, 'javascript'))
    print(f"Found {len(results)} analysis results:")
    
    error_count = sum(1 for r in results if r['isError'])
    print(f"Errors found: {error_count}")
    
    # Show structure
    for result in results[:10]:  # Show first 10 results
        if not result['isError']:
            print(f"✅ Line {result['startLine']}: {result['type']}")

if __name__ == "__main__":
    test_javascript_with_error()
    test_valid_javascript()